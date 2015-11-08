*** Settings ***
Documentation	Test suite for working with GitHub.
...

Resource		github-keywords.robot

Test Setup		Create GitHub Session
Test Teardown	Tear Down

*** Test Cases ***
Git push to remote
	Given a remote repo "${YOUR_GITHUB_REPO}" on Github
	And a local clone repo "${YOUR_GITHUB_REPO}-local"
	When I push a new file "to-be-pushed.md" to remote
	Then remote should have the same file

*** Keywords ***
a remote repo "${repo}" on Github
	Set Test Variable	${remote-repo}	${repo}
	Should Exist Remote Repo	${remote-repo}

a local clone repo "${repo}"
	Set Test Variable	${local-repo}	${repo}
	Clone Local Repo	${remote-repo}	${local-repo}

I push a new file "${file}" to remote
	Set Test Variable	${path}	${file}
	Set Test Variable	${file-content}	\# To Be Pushed
	Should Not Exist Remote File	${remote-repo}	${path}
	Create Local File and Commit	${local-repo}	${path}	${file-content}
	Push Local Changes to Remote	${local-repo}

remote should have the same file
	${remote-file-content} =	Get Content From Remote Repo	${remote-repo}	${path}
	Should Be Equal	${remote-file-content}	${file-content}	Fail: remote file != local file

Tear Down
	Remove Local File and Commit	${local-repo}	${path}
	Push Local Changes to Remote	${local-repo}
	Remove Local Repo	${local-repo}
	Delete All Sessions