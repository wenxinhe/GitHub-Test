*** Settings ***
Documentation	Test suite for working with GitHub.
...

Resource		github-keywords.robot

Test Setup		Create GitHub Session
Test Teardown	Tear Down

*** Test Cases ***
Git pull from remote
	Given a remote repo "${YOUR_GITHUB_REPO}" on Github
	And a local clone repo "${YOUR_GITHUB_REPO}-local"
	When I pull a new file "to-be-pulled.md" from remote
	Then local should have the same file

*** Keywords ***
a remote repo "${repo}" on Github
	Set Test Variable	${remote-repo}	${repo}
	Should Exist Remote Repo	${remote-repo}

a local clone repo "${repo}"
	Set Test Variable	${local-repo}	${repo}
	Clone Local Repo	${remote-repo}	${local-repo}

I pull a new file "${file}" from remote
	Set Test Variable	${path}	${file}
	Set Test Variable	${file-content}	\# To Be Pulled
	Should Not Exist Local File	${local-repo}	${path}
	Create File on Remote Repo	${remote-repo}	${path}	${file-content}
	Pull Remote Changes to Local	${local-repo}

local should have the same file
	${local-file-content} =	Get File	${local-repo}${/}${path}
	Should Contain	${local-file-content}	${file-content}	Fail: local file != remote file

Tear Down
	Remove Local File and Commit	${local-repo}	${path}
	Push Local Changes to Remote	${local-repo}
	Remove Local Repo	${local-repo}
	Delete All Sessions