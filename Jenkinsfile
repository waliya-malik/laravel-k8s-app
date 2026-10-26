pipeline {
    agent any
    environment {
        KUBECONFIG = '/var/lib/jenkins/.kube/config'
        KUBECTL    = '/snap/bin/kubectl'
    }
    stages {
        stage('Build Image') {
            steps {
                sh 'docker build -t laravel-k8s-app:latest .'
            }
        }
        stage('Load Images into Kubernetes') {
            steps {
                sh '''
                    docker image inspect mysql:8.0 > /dev/null 2>&1 || docker pull mysql:8.0
                    docker save mysql:8.0 | docker exec -i minikube ctr -n k8s.io images import -
                    docker save laravel-k8s-app:latest | docker exec -i minikube ctr -n k8s.io images import -
                '''
            }
        }
        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                    $KUBECTL apply -f k8s/
                    $KUBECTL rollout restart deployment/laravel-new
                    $KUBECTL rollout status deployment/mysql-new --timeout=300s
                    $KUBECTL rollout status deployment/laravel-new --timeout=300s
                    $KUBECTL get pods,svc -l 'app in (laravel-new,mysql-new)'
                '''
            }
        }
        stage('Test') {
            steps {
                sh '''
                    echo "Test 1: Database connectivity"
                    DB_OK=no
                    for i in $(seq 1 24); do
                        if $KUBECTL exec deploy/laravel-new -- php artisan migrate:status; then DB_OK=yes; break; fi
                        echo "MySQL not ready yet, retrying in 5 seconds..."
                        sleep 5
                    done
                    [ "$DB_OK" = "yes" ] || { echo "TEST FAILED: database"; exit 1; }

                    echo "Test 2: HTTP response from laravel-new service"
                    for i in $(seq 1 12); do
                        CODE=$($KUBECTL exec deploy/laravel-new -- curl -s -o /dev/null -w "%{http_code}" http://laravel-new || true)
                        echo "HTTP status: $CODE"
                        if [ "$CODE" = "200" ]; then echo "TEST PASSED"; exit 0; fi
                        sleep 5
                    done
                    echo "TEST FAILED: http"; exit 1
                '''
            }
        }
    }
}
