// SPDX-FileCopyrightText: 2021-2025 Zextras <https://www.zextras.com>
//
// SPDX-License-Identifier: AGPL-3.0-only

library(
    identifier: 'jenkins-lib-common@1.3.0',
    retriever: modernSCM([
        $class: 'GitSCMSource',
        credentialsId: 'jenkins-integration-with-github-account',
        remote: 'git@github.com:zextras/jenkins-lib-common.git',
    ])
)

pipeline {
    agent {
        node {
            label 'base'
        }
    }

    options {
        skipDefaultCheckout()
        buildDiscarder(logRotator(numToKeepStr: '25'))
        timeout(time: 2, unit: 'HOURS')
    }

    stages {
        stage('Setup') {
            steps {
                checkout scm
                script {
                    gitMetadata()
                }
            }
        }

        stage('Build') {
            steps {
                echo 'Building deb/rpm packages'
                buildStage([
                    ubuntuSinglePkg: true,
                    rockySinglePkg: true,
                ])
            }
        }

        stage('Upload artifacts')
        {
            tools {
                jfrog 'jfrog-cli'
            }
            steps {
                uploadStage(
                    packages: yapHelper.getPackageNames(),
                    ubuntuSinglePkg: true,
                    rockySinglePkg: true
                )
            }
        }
    }
}
