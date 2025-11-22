# memo-deploy

`memo-server` 앱과 PostgreSQL을 **Helm**/ArgoCD로 배포하기 위한 매니페스트입니다. `dev`/`prod` 값을 분리한 Helm 차트를 사용하며, memo-server 레포의 GitHub Actions가 Helm values의 이미지 태그를 업데이트하고 해당 브랜치로 커밋/푸시합니다.

## 디렉터리 구조
- `helm/memo-server`: Helm 차트
  - `values.yaml`: dev 기본값
  - `values-prod.yaml`: prod 값 오버라이드
- `argocd`: ArgoCD Application 예제 매니페스트

## 사용법
### Helm 직접 배포
```bash
# 개발 환경
helm upgrade --install memo-dev ./helm/memo-server -f helm/memo-server/values.yaml -n memo-dev --create-namespace

# 운영 환경
helm upgrade --install memo-prod ./helm/memo-server -f helm/memo-server/values-prod.yaml -n memo-prod --create-namespace
```
- nginx-ingress가 `nginx` 클래스 이름으로 설치되어 있다고 가정합니다.
- Ingress 호스트: dev=`memo-dev.local`, prod=`memo.example.com` (필요에 맞게 수정 후 /etc/hosts 혹은 DNS 설정).

### ArgoCD
`argocd` 디렉터리 내 매니페스트를 참고하여 repo URL/프로젝트/대상 네임스페이스를 조정합니다. dev는 `values.yaml`, prod는 `values-prod.yaml`을 사용하도록 설정되어 있습니다.

## CI/CD 흐름 (memo-server에서 동작)
- `dev` 브랜치 push: GHCR에 `dev` 및 타임스탬프 태그로 이미지 push 후, 이 레포의 `dev` 브랜치 `helm/memo-server/values.yaml`의 `image.tag`를 업데이트하고 커밋/푸시합니다.
- `main` 브랜치 push: 동일하게 `main`(prod)용 태그를 `helm/memo-server/values-prod.yaml`에 업데이트하되, GitHub 환경 보호(Production)를 통해 수동 승인을 거친 뒤 실행하도록 설계되어 있습니다.

## 설정 변경 포인트
- 실제 GHCR 경로에 맞게 `helm/memo-server/values*.yaml`의 `image.repository` 값을 원하는 레지스트리 경로로 맞추세요. (CI가 자동으로 덮어씁니다)
- DB 계정/패스워드는 `values*.yaml`의 `database` 항목을 사용합니다. 운영 환경에서는 SealedSecret/외부 시크릿 관리로 교체하세요(예: ExternalSecrets).
- 리소스 요구사항/replica 수는 `values*.yaml`에서 조정할 수 있습니다.

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
