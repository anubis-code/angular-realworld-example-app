pipeline {
  agent {
    label "jenkins-jx"
  }
  environment {
    ORG = ''
    APP_NAME = ''
    CHARTMUSEUM_CREDS = credentials('jenkins-x-chartmuseum')
    DOCKER_REGISTRY_ORG = ''
    UPSOURCE_URL = ""
    UPSOURCE_PROJECT = ""
    UPSOURCE_AUTH = credentials('upsource_auth_live')
  }
  stages {
    stage('Notify Upsource') {
      steps {
        container('jx-base') {
          sh script: './notify_upsource.sh in_progress'
        }
      }
    }
    stage('CI Build and push snapshot') {
      when {
        not {
            branch 'master'
          }
        }
      environment {
        ENV = "test"
        PREVIEW_TAG = "0.0.0-SNAPSHOT-$BRANCH_NAME-$BUILD_NUMBER"
        PREVIEW_NAMESPACE = "$APP_NAME-$BRANCH_NAME".toLowerCase()
        HELM_RELEASE = "$PREVIEW_NAMESPACE".toLowerCase()
        PREVIEW_VERSION = sh(script: "echo ${PREVIEW_TAG}  | sed 's/\\//\\-/g'", ,returnStdout: true).trim()
      }
      steps {
        container('jx-base')
          sh "export VERSION=$PREVIEW_VERSION && skaffold build -f skaffold.yaml"
          sh "jx step post build --image $DOCKER_REGISTRY/$ORG/$APP_NAME:$PREVIEW_VERSION"
          dir('./charts/preview') {
            sh "make preview"
            sh "jx preview --app $APP_NAME --dir ../.."
          }
        }
      }
    stage('Build Release') {
      when {
        branch 'master'
      }
      steps {
        container('python') {

          // ensure we're not on a detached head
          sh "git checkout master"
          sh "git config --global credential.helper store"
          sh "jx step git credentials"

          // so we can retrieve the version in later steps
          sh "echo \$(jx-release-version) > VERSION"
          sh "jx step tag --version \$(cat VERSION)"
          sh "python -m unittest"
          sh "export VERSION=`cat VERSION` && skaffold build -f skaffold.yaml"
          sh "jx step post build --image $DOCKER_REGISTRY/$ORG/$APP_NAME:\$(cat VERSION)"
        }
      }
    }
    stage('Promote to Environments') {
      when {
        branch 'master'
      }
      steps {
        container('python') {
          dir('./charts/gig-api') {
            sh "jx step changelog --version v\$(cat ../../VERSION)"

            // release the helm chart
            sh "jx step helm release"

            // promote through all 'Auto' promotion Environments
            sh "jx promote -b --all-auto --timeout 1h --version \$(cat ../../VERSION)"
          }
        }
      }
    }
  }
  post {
        success {
          container('jx-base') {
            sh script: './notify_upsource.sh success'
          }
          cleanWs()
        }

        aborted {
          container('jx-base') {
            sh script: './notify_upsource.sh failed'
          }
          cleanWs()
        }

        failure {
          container('jx-base') {
            sh script: './notify_upsource.sh failed'
          }
          cleanWs()
        }
  }
}
