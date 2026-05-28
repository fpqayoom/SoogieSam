@tool
extends Node

signal request_completed(tag: String, data: Variant)
signal request_failed(tag: String, message: String)
signal rate_limit_updated(remaining: int)

const BASE = "https://api.github.com"
const ACCEPT = "application/vnd.github+json"
const VER = "2022-11-28"

var token = ""
var rate = 60

func set_token(t: String):
	token = t.strip_edges()

func get_token() -> String:
	return token

func has_token() -> bool:
	return token.length() > 0

func fetch_user():
	http_get("/user", "user")

func fetch_my_repos(page = 1):
	http_get("/user/repos?sort=updated&per_page=30&page=%d" % page, "repos")

func search_repos(q: String, page = 1):
	http_get("/search/repositories?q=%s&sort=updated&per_page=20&page=%d" % [q.uri_encode(), page], "search_repos")

func fetch_branches(owner: String, repo: String):
	http_get("/repos/%s/%s/branches?per_page=50" % [owner, repo], "branches")

func create_branch(owner: String, repo: String, branch: String, sha: String):
	http_post("/repos/%s/%s/git/refs" % [owner, repo], {"ref": "refs/heads/" + branch, "sha": sha}, "create_branch")

func delete_branch(owner: String, repo: String, branch: String):
	http_delete("/repos/%s/%s/git/refs/heads/%s" % [owner, repo, branch.uri_encode()], "delete_branch")

func merge_branches(owner: String, repo: String, base: String, head: String, msg: String):
	http_post("/repos/%s/%s/merges" % [owner, repo], {"base": base, "head": head, "commit_message": msg}, "merge")

func create_repo(name: String, desc: String, private: bool):
	http_post("/user/repos", {"name": name, "description": desc, "private": private, "auto_init": true}, "create_repo")

func fetch_commits(owner: String, repo: String, branch = "", page = 1):
	var path = "/repos/%s/%s/commits?per_page=30&page=%d" % [owner, repo, page]
	if branch != "": path += "&sha=" + branch.uri_encode()
	http_get(path, "commits")

func fetch_commit(owner: String, repo: String, sha: String):
	http_get("/repos/%s/%s/commits/%s" % [owner, repo, sha], "commit_detail")

func fetch_tree(owner: String, repo: String, branch: String):
	http_get("/repos/%s/%s/git/trees/%s?recursive=1" % [owner, repo, branch.uri_encode()], "tree")

func fetch_file_meta(owner: String, repo: String, path: String, branch: String):
	http_get("/repos/%s/%s/contents/%s?ref=%s" % [owner, repo, path.uri_encode(), branch.uri_encode()], "file_meta")

func push_file(owner: String, repo: String, path: String, msg: String, content_b64: String, sha: String, branch: String):
	var body = {"message": msg, "content": content_b64, "branch": branch}
	if sha != "": body["sha"] = sha
	http_put("/repos/%s/%s/contents/%s" % [owner, repo, path.uri_encode()], body, "push_file")

func push_commit(owner: String, repo: String, branch: String, files: Array, msg: String, parent_sha: String, tree_sha: String):
	var state = {"owner": owner, "repo": repo, "branch": branch, "files": files, "message": msg, "parent_sha": parent_sha, "tree_sha": tree_sha, "blobs": [], "idx": 0}
	push_blob(state)

func fetch_pulls(owner: String, repo: String, state = "open", page = 1):
	http_get("/repos/%s/%s/pulls?state=%s&per_page=30&page=%d" % [owner, repo, state, page], "pulls")

func create_pr(owner: String, repo: String, title: String, body: String, head: String, base: String):
	http_post("/repos/%s/%s/pulls" % [owner, repo], {"title": title, "body": body, "head": head, "base": base}, "create_pr")

func merge_pr(owner: String, repo: String, number: int, msg: String):
	http_put("/repos/%s/%s/pulls/%d/merge" % [owner, repo, number], {"commit_message": msg, "merge_method": "merge"}, "merge_pr")

func close_pr(owner: String, repo: String, number: int):
	http_patch("/repos/%s/%s/pulls/%d" % [owner, repo, number], {"state": "closed"}, "close_pr")

func fetch_issues(owner: String, repo: String, state = "open", page = 1):
	http_get("/repos/%s/%s/issues?state=%s&per_page=30&page=%d" % [owner, repo, state, page], "issues")

func create_issue(owner: String, repo: String, title: String, body: String):
	http_post("/repos/%s/%s/issues" % [owner, repo], {"title": title, "body": body}, "create_issue")

func close_issue(owner: String, repo: String, number: int):
	http_patch("/repos/%s/%s/issues/%d" % [owner, repo, number], {"state": "closed"}, "close_issue")

func headers():
	var h = ["Accept: " + ACCEPT, "X-GitHub-Api-Version: " + VER, "User-Agent: qugit", "Content-Type: application/json"]
	if token != "": h.append("Authorization: Bearer " + token)
	return h

func http_get(path: String, tag: String):
	fire(BASE + path, HTTPClient.METHOD_GET, "", tag)

func http_post(path: String, body, tag: String):
	fire(BASE + path, HTTPClient.METHOD_POST, JSON.stringify(body), tag)

func http_put(path: String, body, tag: String):
	fire(BASE + path, HTTPClient.METHOD_PUT, JSON.stringify(body), tag)

func http_patch(path: String, body, tag: String):
	fire(BASE + path, HTTPClient.METHOD_PATCH, JSON.stringify(body), tag)

func http_delete(path: String, tag: String):
	fire(BASE + path, HTTPClient.METHOD_DELETE, "", tag)

func fire(url: String, method: int, body: String, tag: String):
	var h = HTTPRequest.new()
	h.use_threads = true
	add_child(h)
	var _tag = tag
	h.request_completed.connect(func(res, code, hdrs, raw): handle(res, code, hdrs, raw, _tag); h.queue_free())
	h.request(url, headers(), method, body)

func handle(res: int, code: int, hdrs, raw, tag: String):
	for h in hdrs:
		if h.to_lower().begins_with("x-ratelimit-remaining:"):
			rate = h.split(":")[1].strip_edges().to_int()
			emit_signal("rate_limit_updated", rate)
	if res != HTTPRequest.RESULT_SUCCESS:
		emit_signal("request_failed", tag, "Network error")
		return
	if code == 204:
		emit_signal("request_completed", tag, {})
		return
	var text = raw.get_string_from_utf8()
	var parsed = JSON.parse_string(text)
	if parsed == null:
		emit_signal("request_failed", tag, "Parse error")
		return
	if code >= 400:
		var msg = parsed.get("message", "HTTP %d" % code) if parsed is Dictionary else "HTTP %d" % code
		emit_signal("request_failed", tag, msg)
		return
	emit_signal("request_completed", tag, parsed)

func push_blob(state):
	var idx = state["idx"]
	var files = state["files"]
	if idx >= files.size():
		push_tree(state)
		return
	var file = files[idx]
	var h = HTTPRequest.new()
	h.use_threads = true
	add_child(h)
	var _state = state
	h.request_completed.connect(func(res, code, _h, raw): 
		h.queue_free()
		if res == HTTPRequest.RESULT_SUCCESS and code < 400:
			var p = JSON.parse_string(raw.get_string_from_utf8())
			if p is Dictionary:
				_state["blobs"].append({"path": file["path"], "sha": p.get("sha",""), "mode": "100644", "type": "blob"})
		_state["idx"] += 1
		push_blob(_state)
	)
	h.request(BASE + "/repos/%s/%s/git/blobs" % [_state["owner"], _state["repo"]], headers(), HTTPClient.METHOD_POST, JSON.stringify({"content": file["content_b64"], "encoding": "base64"}))

func push_tree(state):
	var h = HTTPRequest.new()
	h.use_threads = true
	add_child(h)
	var _state = state
	h.request_completed.connect(func(res, code, _h, raw):
		h.queue_free()
		if res == HTTPRequest.RESULT_SUCCESS and code < 400:
			var p = JSON.parse_string(raw.get_string_from_utf8())
			if p is Dictionary:
				_state["tree_sha"] = p.get("sha","")
				push_commit_obj(_state)
	)
	var body = {"base_tree": _state["tree_sha"], "tree": _state["blobs"]}
	h.request(BASE + "/repos/%s/%s/git/trees" % [_state["owner"], _state["repo"]], headers(), HTTPClient.METHOD_POST, JSON.stringify(body))

func push_commit_obj(state):
	var h = HTTPRequest.new()
	h.use_threads = true
	add_child(h)
	var _state = state
	h.request_completed.connect(func(res, code, _h, raw):
		h.queue_free()
		if res == HTTPRequest.RESULT_SUCCESS and code < 400:
			var p = JSON.parse_string(raw.get_string_from_utf8())
			if p is Dictionary:
				_state["commit_sha"] = p.get("sha","")
				push_ref(_state)
	)
	var body = {"message": _state["message"], "tree": _state["tree_sha"], "parents": [_state["parent_sha"]]}
	h.request(BASE + "/repos/%s/%s/git/commits" % [_state["owner"], _state["repo"]], headers(), HTTPClient.METHOD_POST, JSON.stringify(body))

func push_ref(state):
	var h = HTTPRequest.new()
	h.use_threads = true
	add_child(h)
	h.request_completed.connect(func(res, code, _h, raw):
		h.queue_free()
		if res == HTTPRequest.RESULT_SUCCESS and code < 400:
			emit_signal("request_completed", "push_commit", JSON.parse_string(raw.get_string_from_utf8()))
		else:
			emit_signal("request_failed", "push_commit", "Failed")
	)
	var body = {"sha": state["commit_sha"], "force": false}
	h.request(BASE + "/repos/%s/%s/git/refs/heads/%s" % [state["owner"], state["repo"], state["branch"].uri_encode()], headers(), HTTPClient.METHOD_PATCH, JSON.stringify(body))
