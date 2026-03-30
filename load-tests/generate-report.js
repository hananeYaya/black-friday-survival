const fs = require('fs');
const path = require('path');


class LoadTestReporter {
    constructor() {
        this.reports = [];
        this.outputDir = path.join(__dirname, 'reports');
    }

    loadReports() {
        const reportFiles = fs.readdirSync(__dirname)
            .filter(file => file.endsWith('-report.json'))
            .map(file => path.join(__dirname, file));

        this.reports = reportFiles.map(file => {
            try {
                return JSON.parse(fs.readFileSync(file, 'utf8'));
            } catch (e) {
                console.warn(`Could not parse ${file}: ${e.message}`);
                return null;
            }
        }).filter(Boolean);

        return this.reports.length;
    }

    generateSummary() {
        if (this.reports.length === 0) {
            return { error: 'No reports found' };
        }

        const summary = {
            timestamp: new Date().toISOString(),
            totalTests: this.reports.length,
            overall: {
                totalRequests: 0,
                totalErrors: 0,
                avgResponseTime: 0,
                minResponseTime: Infinity,
                maxResponseTime: 0,
                p95ResponseTime: 0,
                p99ResponseTime: 0
            },
            tests: []
        };

        this.reports.forEach((report, index) => {
            const testSummary = {
                name: report.aggregate ? `Test ${index + 1}` : 'Unknown',
                timestamp: report.aggregate?.timestamp || new Date().toISOString(),
                duration: report.aggregate?.phases?.[0]?.duration || 0,
                scenarios: report.aggregate?.scenariosCreated || 0,
                requests: report.aggregate?.counters?.['http.requests'] || 0,
                responses: report.aggregate?.counters?.['http.responses'] || 0,
                errors: report.aggregate?.counters?.['http.codes.4xx'] || 0 +
                    report.aggregate?.counters?.['http.codes.5xx'] || 0,
                rps: report.aggregate?.rates?.['http.request_rate'] || 0,
                latency: {
                    min: report.aggregate?.summaries?.['http.response_time']?.min || 0,
                    max: report.aggregate?.summaries?.['http.response_time']?.max || 0,
                    median: report.aggregate?.summaries?.['http.response_time']?.median || 0,
                    p95: report.aggregate?.summaries?.['http.response_time']?.p95 || 0,
                    p99: report.aggregate?.summaries?.['http.response_time']?.p99 || 0
                }
            };

            summary.overall.totalRequests += testSummary.requests;
            summary.overall.totalErrors += testSummary.errors;
            summary.overall.avgResponseTime += testSummary.latency.median;
            summary.overall.minResponseTime = Math.min(summary.overall.minResponseTime, testSummary.latency.min);
            summary.overall.maxResponseTime = Math.max(summary.overall.maxResponseTime, testSummary.latency.max);

            summary.tests.push(testSummary);
        });

        summary.overall.avgResponseTime = summary.overall.avgResponseTime / summary.totalTests;
        summary.overall.errorRate = (summary.overall.totalErrors / summary.overall.totalRequests) * 100;

        return summary;
    }

    generateHTML(summary) {
        const html = `
<!DOCTYPE html>
<html>
<head>
    <title>Load Test Report - Black Friday Survival</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #2c3e50; color: white; padding: 20px; border-radius: 5px; }
        .summary { background: #ecf0f1; padding: 20px; margin: 20px 0; border-radius: 5px; }
        .test-card { border: 1px solid #ddd; margin: 10px 0; padding: 15px; border-radius: 5px; }
        .metric { display: inline-block; margin: 5px 10px 5px 0; }
        .good { color: #27ae60; }
        .warning { color: #f39c12; }
        .error { color: #e74c3c; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Load Test Report</h1>
        <p>Black Friday Survival E-commerce Platform</p>
        <p>Generated: ${new Date(summary.timestamp).toLocaleString()}</p>
    </div>

    <div class="summary">
        <h2>Overall Summary</h2>
        <div class="metric"><strong>Total Tests:</strong> ${summary.totalTests}</div>
        <div class="metric"><strong>Total Requests:</strong> ${summary.overall.totalRequests.toLocaleString()}</div>
        <div class="metric"><strong>Error Rate:</strong>
            <span class="${summary.overall.errorRate > 5 ? 'error' : summary.overall.errorRate > 1 ? 'warning' : 'good'}">
                ${summary.overall.errorRate.toFixed(2)}%
            </span>
        </div>
        <div class="metric"><strong>Avg Response Time:</strong> ${summary.overall.avgResponseTime.toFixed(2)}ms</div>
        <div class="metric"><strong>Min Response Time:</strong> ${summary.overall.minResponseTime}ms</div>
        <div class="metric"><strong>Max Response Time:</strong> ${summary.overall.maxResponseTime}ms</div>
    </div>

    <h2>Individual Test Results</h2>
    <table>
        <tr>
            <th>Test</th>
            <th>Duration</th>
            <th>Requests</th>
            <th>RPS</th>
            <th>Errors</th>
            <th>Median (ms)</th>
            <th>P95 (ms)</th>
            <th>P99 (ms)</th>
        </tr>
        ${summary.tests.map((test, index) => `
        <tr>
            <td>${test.name}</td>
            <td>${test.duration}s</td>
            <td>${test.requests.toLocaleString()}</td>
            <td>${test.rps.toFixed(2)}</td>
            <td class="${test.errors > 0 ? 'error' : 'good'}">${test.errors}</td>
            <td>${test.latency.median.toFixed(2)}</td>
            <td>${test.latency.p95.toFixed(2)}</td>
            <td>${test.latency.p99.toFixed(2)}</td>
        </tr>
        `).join('')}
    </table>

    <div class="summary">
        <h3>Recommendations</h3>
        <ul>
            ${summary.overall.errorRate > 5 ? '<li class="error">High error rate detected - investigate server issues</li>' : ''}
            ${summary.overall.avgResponseTime > 1000 ? '<li class="warning">Slow response times - consider optimization</li>' : ''}
            ${summary.overall.avgResponseTime < 500 ? '<li class="good">Excellent performance!</li>' : ''}
            <li>Monitor database performance during peak loads</li>
            <li>Consider implementing caching for frequently accessed data</li>
            <li>Review auto-scaling configurations</li>
        </ul>
    </div>
</body>
</html>`;

        return html;
    }

    saveReport(summary) {
        if (!fs.existsSync(this.outputDir)) {
            fs.mkdirSync(this.outputDir);
        }

        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        const jsonFile = path.join(this.outputDir, `summary-${timestamp}.json`);
        const htmlFile = path.join(this.outputDir, `report-${timestamp}.html`);

        fs.writeFileSync(jsonFile, JSON.stringify(summary, null, 2));
        fs.writeFileSync(htmlFile, this.generateHTML(summary));

        console.log(`Reports generated:`);
        console.log(`   JSON: ${jsonFile}`);
        console.log(`   HTML: ${htmlFile}`);

        return { json: jsonFile, html: htmlFile };
    }

    run() {
        console.log('Scanning for Artillery reports...');
        const reportCount = this.loadReports();

        if (reportCount === 0) {
            console.log('No report files found. Run some load tests first!');
            return;
        }

        console.log(`Found ${reportCount} report(s)`);

        const summary = this.generateSummary();
        const files = this.saveReport(summary);

        console.log('Report generation complete!');
        console.log(`Open ${files.html} in your browser to view the report`);
    }
}

if (require.main === module) {
    const reporter = new LoadTestReporter();
    reporter.run();
}

module.exports = LoadTestReporter;