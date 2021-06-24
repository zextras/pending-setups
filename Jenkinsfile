pipeline {
    agent {
        node {
            label 'base-agent-v1'
        }
    }
    parameters {
        booleanParam defaultValue: false, description: 'Whether to upload the packages in playground repositories', name: 'PLAYGROUND'
    }
    options {
        skipDefaultCheckout()
        buildDiscarder(logRotator(numToKeepStr: '25'))
        timeout(time: 2, unit: 'HOURS')
    }
    stages {
        stage('Stash') {
            steps {
                checkout scm
                stash includes: "**", name: 'project'
            }
        }
        stage('Build deb/rpm') {
            parallel {
                stage('Ubuntu 16.04') {
                    agent {
                        node {
                            label 'pacur-agent-ubuntu-16.04-v1'
                        }
                    }
                    steps {
                        unstash 'project'
                        sh 'sudo cp -r * /tmp/'
                        sh 'sudo pacur build ubuntu'
                        stash includes: 'artifacts/', name: 'artifacts-deb'
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: "artifacts/*.deb", fingerprint: true
                        }
                    }
                }

                stage('Centos 7') {
                    agent {
                        node {
                            label 'pacur-agent-centos-7-v1'
                        }
                    }
                    steps {
                        unstash 'project'
                        sh 'sudo cp -r * /tmp/'
                        sh 'sudo pacur build centos'
                        dir("artifacts/") {
                            sh 'echo pending-setups* | sed -E "s#(pending-setups-[0-9.]*).*#\\0 \\1.x86_64.rpm#" | xargs sudo mv'
                        }
                        stash includes: 'artifacts/', name: 'artifacts-rpm'
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: "artifacts/*.rpm", fingerprint: true
                        }
                    }
                }
            }
        }
        stage('Upload To Playground') {
            when {
                anyOf {
                    branch 'playground/*'
                    expression { params.PLAYGROUND == true }
                }
            }
            steps {
                unstash 'artifacts-deb'
                unstash 'artifacts-rpm'
                script {
                    def server = Artifactory.server 'zextras-artifactory'
                    def buildInfo
                    def uploadSpec

                    buildInfo = Artifactory.newBuildInfo()
                    uploadSpec = """{
                        "files": [
                            {
                                "pattern": "pending-setups*.deb",
                                "target": "ubuntu-playground/pool/",
                                "props": "deb.distribution=xenial;deb.distribution=bionic;deb.distribution=focal;deb.component=main;deb.architecture=amd64"
                            },
                            {
                                "pattern": "artifacts/(pending-setups)-(*).rpm",
                                "target": "centos7-playground/zextras/{1}/{1}-{2}.rpm",
                                "props": "rpm.metadata.arch=x86_64;rpm.metadata.vendor=zextras"
                            },
                            {
                                "pattern": "artifacts/(pending-setups)-(*).rpm",
                                "target": "centos8-playground/zextras/{1}/{1}-{2}.rpm",
                                "props": "rpm.metadata.arch=x86_64;rpm.metadata.vendor=zextras"
                            }
                        ]
                    }"""
                    server.upload spec: uploadSpec, buildInfo: buildInfo, failNoOp: false
                }
            }
        }
        stage('Upload & Promotion Config') {
            when {
                buildingTag()
            }
            steps {
                unstash 'artifacts-deb'
                unstash 'artifacts-rpm'
                script {
                    def server = Artifactory.server 'zextras-artifactory'
                    def buildInfo
                    def uploadSpec
                    def config

                    //ubuntu
                    buildInfo = Artifactory.newBuildInfo()
                    buildInfo.name += "-ubuntu"
                    uploadSpec= """{
                        "files": [
                            {
                                "pattern": "artifacts/pending-setups*.deb",
                                "target": "ubuntu-rc/pool/",
                                "props": "deb.distribution=xenial;deb.distribution=bionic;deb.distribution=focal;deb.component=main;deb.architecture=amd64"
                            }
                        ]
                    }"""
                    server.upload spec: uploadSpec, buildInfo: buildInfo, failNoOp: false
                    config = [
                            'buildName'          : buildInfo.name,
                            'buildNumber'        : buildInfo.number,
                            'sourceRepo'         : 'ubuntu-rc',
                            'targetRepo'         : 'ubuntu-release',
                            'comment'            : 'Do not change anything! Just press the button',
                            'status'             : 'Released',
                            'includeDependencies': false,
                            'copy'               : true,
                            'failFast'           : true
                    ]
                    Artifactory.addInteractivePromotion server: server, promotionConfig: config, displayName: "Ubuntu Promotion to Release"
                    server.publishBuildInfo buildInfo

                    //centos7
                    buildInfo = Artifactory.newBuildInfo()
                    buildInfo.name += "-centos7"
                    uploadSpec= """{
                        "files": [
                            {
                                "pattern": "artifacts/(pending-setups)-(*).rpm",
                                "target": "centos7-rc/zextras/{1}/{1}-{2}.rpm",
                                "props": "rpm.metadata.arch=x86_64;rpm.metadata.vendor=zextras"
                            }
                        ]
                    }"""
                    server.upload spec: uploadSpec, buildInfo: buildInfo, failNoOp: false
                    config = [
                            'buildName'          : buildInfo.name,
                            'buildNumber'        : buildInfo.number,
                            'sourceRepo'         : 'centos7-rc',
                            'targetRepo'         : 'centos7-release',
                            'comment'            : 'Do not change anything! Just press the button',
                            'status'             : 'Released',
                            'includeDependencies': false,
                            'copy'               : true,
                            'failFast'           : true
                    ]
                    Artifactory.addInteractivePromotion server: server, promotionConfig: config, displayName: "Centos7 Promotion to Release"
                    server.publishBuildInfo buildInfo

                    //centos8
                    buildInfo = Artifactory.newBuildInfo()
                    buildInfo.name += "-centos8"
                    uploadSpec= """{
                        "files": [
                            {
                                "pattern": "artifacts/(pending-setups)-(*).rpm",
                                "target": "centos8-rc/zextras/{1}/{1}-{2}.rpm",
                                "props": "rpm.metadata.arch=x86_64;rpm.metadata.vendor=zextras"
                            }
                        ]
                    }"""
                    server.upload spec: uploadSpec, buildInfo: buildInfo, failNoOp: false
                    config = [
                            'buildName'          : buildInfo.name,
                            'buildNumber'        : buildInfo.number,
                            'sourceRepo'         : 'centos8-rc',
                            'targetRepo'         : 'centos8-release',
                            'comment'            : 'Do not change anything! Just press the button',
                            'status'             : 'Released',
                            'includeDependencies': false,
                            'copy'               : true,
                            'failFast'           : true
                    ]
                    Artifactory.addInteractivePromotion server: server, promotionConfig: config, displayName: "Centos8 Promotion to Release"
                    server.publishBuildInfo buildInfo
                }
            }
        }
    }
}
