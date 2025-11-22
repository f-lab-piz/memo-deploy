# memo-deploy

`memo-server` 앱과 PostgreSQL을 kustomize/ArgoCD로 배포하기 위한 매니페스트입니다. `dev`/`prod` 오버레이로 환경을 분리하며, memo-server 레포의 GitHub Actions가 이미지 태그를 업데이트하고 해당 브랜치로 커밋/푸시합니다.

## 디렉터리 구조
- `k8s/base`: 공통 리소스 (Deployment/Service/Secret/ConfigMap)
- `k8s/overlays/dev`: 개발 환경 오버레이 (네임스페이스 `memo-dev`, dev ingress)
- `k8s/overlays/prod`: 운영 환경 오버레이 (네임스페이스 `memo-prod`, prod ingress)
- `argocd`: ArgoCD Application 예제 매니페스트

## 사용법
### kustomize 직접 배포
```bash
# 개발 환경
kubectl apply -k k8s/overlays/dev

# 운영 환경
kubectl apply -k k8s/overlays/prod
```
- nginx-ingress가 `nginx` 클래스 이름으로 설치되어 있다고 가정합니다.
- Ingress 호스트: dev=`memo-dev.local`, prod=`memo.example.com` (필요에 맞게 수정 후 /etc/hosts 혹은 DNS 설정).

### ArgoCD
`argocd` 디렉터리 내 매니페스트를 참고하여 repo URL/프로젝트/대상 네임스페이스를 조정합니다. dev는 `targetRevision: dev`, prod는 `targetRevision: main` (또는 prod 브랜치)로 설정되어 있습니다.

## CI/CD 흐름 (memo-server에서 동작)
- `dev` 브랜치 push: GHCR에 `dev` 및 타임스탬프 태그로 이미지 push 후, 이 레포의 `dev` 브랜치 `k8s/overlays/dev/kustomization.yaml`의 `images` 섹션을 업데이트하고 커밋/푸시합니다.
- `main` 브랜치 push: 동일하게 `main`(prod)용 태그를 업데이트하되, GitHub 환경 보호(Production)를 통해 수동 승인을 거친 뒤 실행하도록 설계되어 있습니다.

## 설정 변경 포인트
- 실제 GHCR 경로에 맞게 `k8s/overlays/*/kustomization.yaml`의 `newName` 값을 원하는 레지스트리 경로로 맞추세요. (CI가 자동으로 덮어씁니다)
- `k8s/base/config/memo-db-secret.yaml`은 예시 값입니다. 운영 환경에서는 SealedSecret이나 외부 시크릿 관리 도구로 교체하세요.
- 리소스 요구사항/replica 수는 환경별 patch 파일로 조정할 수 있습니다.

## 로컬 k3d + nginx-ingress + ArgoCD (예시)
```bash
# k3d 클러스터 생성 (80/443 노출)
k3d cluster create memo --port 80:80@loadbalancer --port 443:443@loadbalancer

# nginx ingress (ingress-nginx helm chart)
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx --create-namespace

# ArgoCD 설치
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# ArgoCD Application 적용 (dev 예시)
kubectl apply -f argocd/app-dev.yaml
```
