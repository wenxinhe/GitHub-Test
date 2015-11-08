*** Settings ***
Library	Collections
Library	RequestsLibrary
Library	OperatingSystem

*** Variables ***

*** Keywords ***
######### Remote Operation ##########
Create GitHub Session
	Variable Should Exist 	${USER}	Please set --variable USER:yourUsername
	Variable Should Exist 	${PASSWORD}	Please set --variable PASSWORD:yourPassword
	${auth} =	Create List	${USER}	${PASSWORD}
	Create Session	github	https://api.github.com	auth=${auth}

Should Exist Remote Repo
	[Arguments]	${repo}
	${resp} =	Get Request	github	/user/repos
	Should Be Equal As Strings	${resp.status_code}	200	Fail to list repos on remote: ${resp.json()}	False

	Does Repo Exist on Remote	${repo}	${resp.json()}

	${found} =	Get Variable Value	${found}
	Should Be Equal As Strings	${found}	TRUE	Fatal: remote repo ${repo} does NOT exist, please create ${repo} on GitHub first

Does Repo Exist on Remote
	[Arguments]	${repo}	${remote-repos}
	:FOR	${remote-repo}	IN	@{remote-repos}
	\		${remote-repo-name} =	Get From Dictionary	${remote-repo}	name
	\		Run Keyword If 	'${remote-repo-name}' == '${repo}'
	...		Set Test Variable	${found}	TRUE

Create Remote Repo
	[Arguments]	${repo}
	${resp} =	Post Request	github	/user/repos	data={"name":"${repo}"}
	Should Be Equal As Strings	${resp.status_code}	201	Fail to create remote repo ${repo}: ${resp.json()}	False

Delete Remote Repo
	[Arguments]	${repo}
	${resp} =	Delete Request	github	/repos/${USER}/${repo}
	Should Be Equal As Strings	${resp.status_code}	204	Fail to delete remote repo ${repo}: ${resp.json()}	False

Create File on Remote Repo
	[Arguments]	${repo}	${path}	${file-content}
	${content} =	Run	echo '${file-content}' | base64
	${resp} =	Put Request	github	/repos/${USER}/${repo}/contents/${path}	data={"message":"commit ${path}","content":"${content}"}
	Should Be Equal As Strings	${resp.status_code}	201	Fail to new file ${path} on remote repo ${repo}: ${resp.json()}	False

Get Content From Remote Repo
	[Arguments]	${repo}	${path}
	${resp} =	Wait Until Keyword Succeeds	4x	1000ms
	...	Get File From Remote Repo 	${repo}	${path}
	${content} =	Get Decode Content	${resp.json()}
	[return]	${content}

Get File From Remote Repo
	[Arguments]	${repo}	${path}
	${resp} =	Get Request	github	/repos/${USER}/${repo}/contents/${path}
	Should Be Equal As Strings	${resp.status_code}	200	Fail to get content from ${path} on remote repo ${repo}: ${resp.json()}	False
	[return]	${resp}

Get Decode Content
	[Arguments]	${json}
	${data} =	Get From Dictionary	${json}	content
	${content} =	Run	echo '${data}' | base64 -d
	[return]	${content}

Should Not Exist Remote File
	[Arguments]	${repo}	${path}
	Wait Until Keyword Succeeds	4x	1000ms
	...	Remote File Not Exists	${repo}	${path}

Remote File Not Exists
	[Arguments]	${repo}	${path}
	${resp} =	Get Request	github	/repos/${USER}/${repo}/contents/${path}
	Should Be Equal As Strings	${resp.status_code}	404	Fatal: File ${path} should NOT exist on remote repo ${repo}, but still exists: ${resp.json()}	False

######### Local Operation ##########
Clone Local Repo
	[Arguments]	${remote-repo}	${local-repo}
	Remove Directory	${local-repo}	recursive=True
	${result} =	Run	git clone git@github.com:${USER}/${remote-repo}.git ${local-repo}
	Should Not Contain	${result}	Permission denied	Permission denied, adding SSH key to your GitHub may help	False
	Directory Should Exist	${local-repo}/.git	Fail to clone local repo: ${result}

Create Local File and Commit
	[Arguments]	${repo}	${path}	${content}
	Run	cd ${repo} && echo "${content}" >> ${path}
	Run	cd ${repo} && git add ${path}
	Run	cd ${repo} && git commit -m "commit ${path}"

Should Not Exist Local File
	[Arguments]	${repo}	${path}
	File Should Not Exist	${repo}${/}${path}	Fail: File ${path} should NOT exist on local repo ${repo}, but still exists

Remove Local File and Commit
	[Arguments]	${repo}	${path}
	Run	cd ${repo} && git rm ${path}
	Run	cd ${repo} && git commit -m "rm ${path}"

Pull Remote Changes to Local
	[Arguments]	${local-repo}
	Run	cd ${local-repo} && git pull -u origin master

Push Local Changes to Remote
	[Arguments]	${local-repo}
	Run	cd ${local-repo} && git push -u origin master

Remove Local Repo
	[Arguments]	${local-repo}
	Remove Directory	${local-repo}	recursive=True
