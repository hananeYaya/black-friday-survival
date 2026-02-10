# Guide d'installation - Online Boutique

## Prérequis

Avant de commencer, assurez-vous d'avoir installé les outils suivants :

- [Docker Desktop](https://www.docker.com/products/docker-desktop) (avec Kubernetes activé)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [skaffold 2.0.2+](https://skaffold.dev/docs/install/)
- [Git](https://git-scm.com/downloads)

### Ressources minimales recommandées

| Ressource | Minimum |
|-----------|---------|
| CPU       | 4 coeurs |
| RAM       | 6 Go    |
| Disque    | 32 Go   |

## Installation

### 1. Cloner le projet

```sh
git clone https://github.com/GoogleCloudPlatform/microservices-demo.git
cd microservices-demo/
```

### 2. Lancer un cluster Kubernetes local

Choisissez l'une des options suivantes :

#### Option A : Docker Desktop (recommandé sur Mac/Windows)

1. Ouvrir Docker Desktop
2. Aller dans **Settings > Kubernetes**
3. Cocher **Enable Kubernetes**
4. Dans **Settings > Resources**, configurer au minimum 4 CPUs et 6 Go de RAM
5. Cliquer sur **Apply & Restart**

#### Option B : Minikube

```sh
minikube start --cpus=4 --memory 4096 --disk-size 32g
```

#### Option C : Kind

```sh
kind create cluster
```

### 3. Vérifier la connexion au cluster

```sh
kubectl get nodes
```

Vous devriez voir au moins un noeud en statut `Ready`.

### 4. Déployer l'application

#### Avec Skaffold (build depuis les sources)

```sh
skaffold run
```

> La première exécution peut prendre ~20 minutes car toutes les images Docker doivent être construites.

> Pour le mode développement avec rebuild automatique lors des modifications :
> ```sh
> skaffold dev
> ```

#### Avec les manifests pré-construits (plus rapide)

```sh
kubectl apply -f ./release/kubernetes-manifests.yaml
```

### 5. Vérifier que les pods sont prêts

```sh
kubectl get pods
```

Attendez que tous les pods soient en statut `Running` (cela peut prendre quelques minutes).

### 6. Accéder à l'application

#### Si vous avez utilisé Skaffold ou les manifests Kubernetes :

```sh
kubectl port-forward deployment/frontend 8080:8080
```

Puis ouvrez votre navigateur sur : **http://localhost:8080**

## Arrêt et nettoyage

### Arrêter l'application

Si déployé avec `skaffold run` :
```sh
skaffold delete
```

Si déployé avec `kubectl apply` :
```sh
kubectl delete -f ./release/kubernetes-manifests.yaml
```

### Arrêter le cluster local

- **Docker Desktop** : Désactiver Kubernetes dans les paramètres
- **Minikube** : `minikube stop`
- **Kind** : `kind delete cluster`

## Dépannage

| Problème | Solution |
|----------|----------|
| Pods en `CrashLoopBackOff` | Vérifiez que votre cluster a assez de ressources (CPU/RAM) |
| Images trop longues à build | Utilisez les manifests pré-construits (`kubectl apply -f ./release/kubernetes-manifests.yaml`) |
| `kubectl` ne se connecte pas | Vérifiez que votre cluster est bien démarré avec `docker ps` ou `minikube status` |
| Port 8080 déjà utilisé | Changez le port : `kubectl port-forward deployment/frontend 3000:8080` puis accédez à `http://localhost:3000` |
