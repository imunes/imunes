def targets = []
if (params.TARGETS?.trim()) {
    targets = params.TARGETS.tokenize(',').collect { it.trim() }
}

def linuxAgents = ['arch', 'ubuntu-24.04', 'debian-12']
def freebsdAgents = ['freebsd-14.2', 'freebsd-14.3', 'freebsd-15.0']

properties([
  buildDiscarder(logRotator(numToKeepStr: '30', artifactNumToKeepStr: '10'))
])

pipeline {
	agent none

	parameters {
		string(name: 'IMUNES_REPO', defaultValue: 'https://github.com/imunes/imunes.git', description: 'IMUNES Git repository URL')
		string(name: 'EXAMPLES_REPO', defaultValue: 'https://github.com/imunes/imunes-examples.git', description: 'IMUNES examples Git repository URL')
		string(name: 'EXAMPLES_BRANCH', defaultValue: 'master', description: 'IMUNES examples Git branch')
		string(name: 'FREEBSD_TESTS', defaultValue: '', description: 'FreeBSD tests')
		string(name: 'FREEBSD_JOBS', defaultValue: '8', description: 'FreeBSD parallel jobs')
		string(name: 'LINUX_TESTS', defaultValue: '', description: 'Linux tests')
		string(name: 'LINUX_JOBS', defaultValue: '4', description: 'Linux parallel jobs')
		string(name: 'TARGETS', defaultValue: 'arch,freebsd-14.3', description: 'Comma-separated list of target agents')
		choice(name: 'PLATFORM', choices: ['both', 'freebsd', 'linux'], description: 'Target platform(s) to run tests')
	}


	environment {
		ENV_FILE = '/usr/local/etc/jenkins.env'
		REPO_DIR = '/tmp/imunes_ci'
		TEST_DIR = '/tmp/imunes-examples'
	}

	stages {
		stage('Init') {
			steps {
				script {
					// Override env variable with parameter value
					env.IMUNES_REPO = params.IMUNES_REPO
					env.IMUNES_BRANCH = "${env.BRANCH_NAME}" 
					env.EXAMPLES_REPO = params.EXAMPLES_REPO
					env.EXAMPLES_BRANCH = params.EXAMPLES_BRANCH
					env.FREEBSD_TESTS = params.FREEBSD_TESTS
					env.FREEBSD_JOBS = params.FREEBSD_JOBS
					env.LINUX_TESTS = params.LINUX_TESTS
					env.LINUX_JOBS = params.LINUX_JOBS
				}
			}
		}

		stage('Start All Tests') {
			steps {
				script {
					def jobs = [:]

					for (int i = 0; i < targets.size(); i++) {
						def label = targets[i]
						jobs[label] = {
							node(label) {
								def platform = 'unknown'

								if (linuxAgents.contains(label)) {
									platform = 'linux'
								} else if (freebsdAgents.contains(label)) {
									platform = 'freebsd'
								} else {
									echo "Unknown platform for label '${label}', skipping."
									return
								}

								// Skip this node if it doesn't match the selected platform
								if (params.PLATFORM == 'linux' && platform != 'linux') {
									echo "Skipping ${label} (not a Linux node)"
									return
								} else if (params.PLATFORM == 'freebsd' && platform != 'freebsd') {
									echo "Skipping ${label} (not a FreeBSD node)"
									return
								}

								echo "Running on agent: ${env.NODE_NAME} - Detected platform: ${platform}"
								try {
									stage("Setup on ${env.NODE_NAME} (${label} - ${platform})") {
										echo "Running tests on ${label}"
										sh '''
										uname -a
										'''

										def props = [:]
										def filePath = "${env.ENV_FILE}"

										if (fileExists(filePath)) {
											def fileContent = readFile(filePath)
											fileContent.split('\n').each { line ->
												line = line.trim()
												if (line && !line.startsWith('#') && line.contains('=')) {
													def (key, value) = line.split('=', 2)
													props[key.trim()] = value.trim()
												}
											}

											props.each { k, v ->
												echo "Overriding env: ${k} = ${v}"
												env."${k}" = v
											}
										}
									}

									stage("Install on ${env.NODE_NAME} (${label} - ${platform})") {
										sh """
											rm -rf ${env.REPO_DIR}
											git clone --depth 1 --branch ${env.IMUNES_BRANCH} ${env.IMUNES_REPO} ${env.REPO_DIR}
											cd ${env.REPO_DIR} && sudo make install

											rm -rf ${env.TEST_DIR}
											git clone --depth 1 --branch ${env.EXAMPLES_BRANCH} ${env.EXAMPLES_REPO} ${env.TEST_DIR}
										"""
									}

									stage("Testing on ${env.NODE_NAME} (${label} - ${platform})") {
										def dirName = sh(script: "basename ${env.TEST_DIR}", returnStdout: true).trim()
										def logFile = "${env.TEST_DIR}/test_output_${label}.log"

										def testSet = ""
										def jobNums = ""
										if (platform == 'linux') {
											testSet = "${env.LINUX_TESTS}"
											jobNums = "${env.LINUX_JOBS}"
										} else if (platform == 'freebsd') {
											testSet = "${env.FREEBSD_TESTS}"
											jobNums = "${env.FREEBSD_JOBS}"
										}

										echo "Running tests on ${label} ($testSet)"
										sh """
											cd ${env.TEST_DIR}
											sudo DETAILS=1 LEGACY=1 TESTS="${testSet}" ./testAll.sh -j ${jobNums} | tee ${logFile}
										"""

										sh "tar czf ${dirName}_${label}.tar.gz ${env.TEST_DIR}"
										sh "cp ${logFile} ."

										archiveArtifacts artifacts: "${dirName}_${label}.tar.gz,test_output_${label}.log", allowEmptyArchive: true

										def passed = sh(script: "grep -q \"OK\" ${logFile}", returnStatus: true)
										if (passed == 0) {
											echo "${label} tests passed ✅"
										} else {
											echo "=== ${label} test log start ==="
											sh "cat ${logFile}"
											echo "=== ${label} test log end ==="
											error "${label} tests failed ❌"
										}
									}
								} finally {
									// TODO: test
									echo "🔧 Cleaning up remote machine: ${label}"
									sh "rm -rf ${env.REPO_DIR} ${env.TEST_DIR}"
									sh "sudo killall testAll.sh || true"
									sh "sudo cleanupAll || true"

									if (platform == 'linux') {
										sh '''
											sudo ip -all netns del || true
											for d in $(docker ps -a | awk '{print $NF}'); do
												sudo docker kill $d || true
												sudo docker rm $d || true
											done
										'''
									} else if (platform == 'freebsd') {
										sh '''
											for j in $(sudo jls -a | awk '{print $1}'); do
												sudo jail -r $j || true
											done
										'''
									}
								}
							}
						}
					}

					parallel jobs
				}
			}
		}
	}
}
