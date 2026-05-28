@tool
extends Control

const SAVE_PATH = "user://qugit_auth.cfg"
const IGNORE_EXT = [".uid", ".import", ".tmp", ".bak"]
const IGNORE_DIRS = [".git", ".godot"]

@onready var api = $API
@onready var token_in = %TokenInput
@onready var connect_btn = %ConnectBtn
@onready var status_lbl = %StatusLabel
@onready var rate_lbl = %RateLabel

# Repos
@onready var repo_search = %RepoSearch
@onready var repo_search_btn = %RepoSearchBtn
@onready var repo_list = %RepoList
@onready var repo_detail = %RepoDetail
@onready var repo_prev = %RepoPrev
@onready var repo_next = %RepoNext
@onready var repo_page_lbl = %RepoPageLbl
@onready var new_repo_name = %NewRepoName
@onready var new_repo_desc = %NewRepoDesc
@onready var new_repo_priv = %NewRepoPriv
@onready var new_repo_btn = %NewRepoBtn

# Branches
@onready var br_repo_pick = %BrRepoPick
@onready var br_owner = %BrOwner
@onready var br_repo = %BrRepo
@onready var br_fetch = %BrFetchBtn
@onready var br_list = %BrList
@onready var br_new_name = %BrNewName
@onready var br_from = %BrFrom
@onready var br_create = %BrCreateBtn
@onready var br_delete = %BrDeleteBtn
@onready var merge_base = %MergeBase
@onready var merge_head = %MergeHead
@onready var merge_msg = %MergeMsg
@onready var merge_btn = %MergeBtn

# Files
@onready var file_repo_pick = %FileRepoPick
@onready var file_owner = %FileOwner
@onready var file_repo = %FileRepo
@onready var file_branch = %FileBranch
@onready var file_load = %FileLoadBtn
@onready var scan_btn = %ScanBtn
@onready var file_tree = %FileTree
@onready var file_mode_tabs = %FileModeTabs
@onready var local_path = %LocalPath
@onready var file_content = %FileContent
@onready var queue_list = %QueueList
@onready var right_tabs = %RightTabs
@onready var file_path_lbl = %FilePathLbl
@onready var push_msg = %PushMsg
@onready var push_btn = %PushBtn
@onready var pull_btn = %PullBtn
@onready var push_sel = %PushSelBtn
@onready var push_multi = %PushMultiBtn
@onready var ignore_lbl = %IgnoreLbl
@onready var toggle_ignored = %ToggleIgnoredBtn
@onready var ignored_list = %IgnoredList
@onready var ignore_add_input = %IgnoreAddInput
@onready var ignore_add_btn = %IgnoreAddBtn

# Commits
@onready var cm_repo_pick = %CmRepoPick
@onready var cm_owner = %CmOwner
@onready var cm_repo = %CmRepo
@onready var cm_branch = %CmBranch
@onready var cm_fetch = %CmFetchBtn
@onready var cm_list = %CmList
@onready var cm_prev = %CmPrev
@onready var cm_next = %CmNext
@onready var cm_detail = %CmDetail
@onready var diff_view = %DiffView

# PRs
@onready var pr_repo_pick = %PrRepoPick
@onready var pr_owner = %PrOwner
@onready var pr_repo = %PrRepo
@onready var pr_state_opt = %PrStateOpt
@onready var pr_fetch = %PrFetchBtn
@onready var pr_list = %PrList
@onready var pr_detail = %PrDetail
@onready var pr_merge = %PrMergeBtn
@onready var pr_close = %PrCloseBtn
@onready var pr_title = %PrTitle
@onready var pr_body = %PrBody
@onready var pr_head = %PrHead
@onready var pr_base = %PrBase
@onready var pr_create = %PrCreateBtn

# Issues
@onready var is_repo_pick = %IsRepoPick
@onready var is_owner = %IsOwner
@onready var is_repo = %IsRepo
@onready var is_state_opt = %IsStateOpt
@onready var is_fetch = %IsFetchBtn
@onready var is_list = %IsList
@onready var is_detail = %IsDetail
@onready var is_close = %IsCloseBtn
@onready var is_title = %IsTitle
@onready var is_body = %IsBody
@onready var is_create = %IsCreateBtn

# State
var repos = []
var repos_page = 1
var search_mode = false
var branches = []
var files = []
var ignored_files = []
var queue_files = []
var custom_ignore = []
var file_sha = ""
var file_path = ""
var file_branch_name = ""
var file_is_remote = false
var file_mode = 0
var commits = []
var commits_page = 1
var pulls = []
var sel_pr = -1
var issues = []
var sel_issue = -1
var ctx_owner = ""
var ctx_repo = ""
var ctx_branch = ""
var pending_push = {}

func _ready():
	api.request_completed.connect(_on_done_patched)
	api.request_failed.connect(_on_fail)
	api.rate_limit_updated.connect(_update_rate_limit)

	connect_btn.pressed.connect(_do_connect)
	token_in.text_submitted.connect(_on_token_submitted)

	repo_search_btn.pressed.connect(_repo_search_go)
	repo_search.text_submitted.connect(_on_search_submitted)
	repo_list.item_selected.connect(_on_repo_selected)
	repo_prev.pressed.connect(_prev_repo_page)
	repo_next.pressed.connect(_next_repo_page)
	new_repo_btn.pressed.connect(_do_create_repo)

	br_repo_pick.item_selected.connect(_on_br_pick)
	file_repo_pick.item_selected.connect(_on_file_pick)
	cm_repo_pick.item_selected.connect(_on_cm_pick)
	pr_repo_pick.item_selected.connect(_on_pr_pick)
	is_repo_pick.item_selected.connect(_on_is_pick)

	br_fetch.pressed.connect(_br_fetch)
	br_create.pressed.connect(_br_create)
	br_delete.pressed.connect(_br_delete)
	merge_btn.pressed.connect(_do_merge)

	file_load.pressed.connect(_file_load_remote)
	scan_btn.pressed.connect(_file_scan_local)
	file_tree.select_mode = ItemList.SELECT_MULTI
	file_tree.item_selected.connect(_on_file_tap)
	file_tree.multi_selected.connect(_on_file_multi)
	file_mode_tabs.tab_changed.connect(_on_file_tab)
	right_tabs.tab_changed.connect(_on_right_tab)
	push_btn.pressed.connect(_do_push_one)
	pull_btn.pressed.connect(_do_pull_file)
	push_sel.pressed.connect(_do_push_queue)
	push_multi.pressed.connect(_do_push_all)
	toggle_ignored.pressed.connect(_show_ignored)
	ignore_add_btn.pressed.connect(_do_add_ignore)
	ignored_list.item_selected.connect(_on_ignored_tap)

	cm_fetch.pressed.connect(_cm_fetch)
	cm_list.item_selected.connect(_on_commit_selected)
	cm_prev.pressed.connect(_prev_commit_page)
	cm_next.pressed.connect(_next_commit_page)

	pr_fetch.pressed.connect(_pr_fetch)
	pr_list.item_selected.connect(_on_pr_selected)
	pr_merge.pressed.connect(_do_pr_merge)
	pr_close.pressed.connect(_do_pr_close)
	pr_create.pressed.connect(_do_pr_create)

	is_fetch.pressed.connect(_is_fetch)
	is_list.item_selected.connect(_on_issue_selected)
	is_close.pressed.connect(_do_issue_close)
	is_create.pressed.connect(_do_issue_create)

	_load_token()

# --- SAFE CALLBACKS ---
func _on_token_submitted(txt: String): _do_connect()
func _on_search_submitted(txt: String): _repo_search_go()
func _update_rate_limit(r: int): rate_lbl.text = "API: %d left" % r
func _prev_repo_page(): repos_page = max(1, repos_page - 1); _repo_load_page()
func _next_repo_page(): repos_page += 1; _repo_load_page()
func _prev_commit_page(): commits_page = max(1, commits_page - 1); _cm_fetch()
func _next_commit_page(): commits_page += 1; _cm_fetch()
func _on_br_pick(i: int): _pick_repo(br_owner, br_repo, i)
func _on_file_pick(i: int): _pick_repo(file_owner, file_repo, i)
func _on_cm_pick(i: int): _pick_repo(cm_owner, cm_repo, i)
func _on_pr_pick(i: int): _pick_repo(pr_owner, pr_repo, i)
func _on_is_pick(i: int): _pick_repo(is_owner, is_repo, i)
# ----------------------------------------------

func _load_token():
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		var tok = cfg.get_value("auth", "token", "")
		if tok != "":
			token_in.text = tok
			api.set_token(tok)
			_set_status("Saved token — connecting…", false)
			api.fetch_user()
			return
	_set_status("Enter token and click Connect", false)

func _save_token(tok: String):
	var cfg = ConfigFile.new()
	cfg.set_value("auth", "token", tok)
	cfg.save(SAVE_PATH)

func _do_connect():
	var tok = token_in.text.strip_edges()
	if tok == "": _set_status("Token empty", true); return
	api.set_token(tok)
	_set_status("Verifying…", false)
	api.fetch_user()

func _repo_search_go():
	repos_page = 1
	var q = repo_search.text.strip_edges()
	search_mode = q != ""
	if search_mode: api.search_repos(q, 1)
	else: api.fetch_my_repos(1)
	_set_status("Loading repos…", false)

func _repo_load_page():
	if search_mode: api.search_repos(repo_search.text.strip_edges(), repos_page)
	else: api.fetch_my_repos(repos_page)

func _populate_repos(data):
	repos = data
	repo_list.clear()
	var picks = [br_repo_pick, file_repo_pick, cm_repo_pick, pr_repo_pick, is_repo_pick]
	for p in picks: p.clear(); p.add_item("— select —")
	for r in data:
		if r is Dictionary:
			var full = r.get("full_name", "?")
			repo_list.add_item("%s ★%d" % [full, r.get("stargazers_count", 0)])
			for p in picks: p.add_item(full)
	repo_page_lbl.text = "Page %d" % repos_page
	repo_prev.disabled = repos_page <= 1

func _on_repo_selected(idx):
	if idx < 0 or idx >= repos.size(): return
	var r = repos[idx]
	ctx_owner = r.get("owner", {}).get("login", "")
	ctx_repo = r.get("name", "")
	ctx_branch = r.get("default_branch", "main")
	var desc = r.get("description", "") if r.get("description") != null else ""
	repo_detail.text = "[b]%s[/b]\n%s\n\n★%d  🍴%d\nLang: %s | Branch: %s | Issues: %d\n\n[url]%s[/url]" % [
		r.get("full_name", ""), desc, r.get("stargazers_count", 0), r.get("forks_count", 0),
		r.get("language", "N/A") if r.get("language") != null else "N/A",
		r.get("default_branch", "main"), r.get("open_issues_count", 0), r.get("html_url", "")]
	for n in [br_owner, file_owner, cm_owner, pr_owner, is_owner]: n.text = ctx_owner
	for n in [br_repo, file_repo, cm_repo, pr_repo, is_repo]: n.text = ctx_repo
	cm_branch.text = ctx_branch

func _pick_repo(owner_node, repo_node, idx):
	var real = idx - 1
	if real < 0 or real >= repos.size(): return
	var r = repos[real]
	owner_node.text = r.get("owner", {}).get("login", "")
	repo_node.text = r.get("name", "")

func _do_create_repo():
	var name = new_repo_name.text.strip_edges()
	if name == "": _set_status("Name required", true); return
	api.create_repo(name, new_repo_desc.text.strip_edges(), new_repo_priv.button_pressed)
	_set_status("Creating…", false)

func _br_fetch():
	var o = br_owner.text.strip_edges()
	var r = br_repo.text.strip_edges()
	if o == "" or r == "": _set_status("Owner+repo required", true); return
	api.fetch_branches(o, r)

func _populate_branches(data):
	branches = data
	br_list.clear()
	for p in [br_from, merge_base, merge_head, file_branch]: p.clear()
	for b in data:
		if b is Dictionary:
			var bname = b.get("name", "")
			br_list.add_item(bname)
			br_from.add_item(bname)
			merge_base.add_item(bname)
			merge_head.add_item(bname)
			file_branch.add_item(bname)
	for i in branches.size():
		if branches[i].get("name", "") == ctx_branch:
			br_from.select(i); file_branch.select(i); break

func _br_create():
	var name = br_new_name.text.strip_edges()
	if name == "": _set_status("Name required", true); return
	var idx = br_from.selected
	if idx < 0: _set_status("Select source", true); return
	var sha = branches[idx].get("commit", {}).get("sha", "")
	if sha == "": _set_status("No SHA", true); return
	api.create_branch(br_owner.text.strip_edges(), br_repo.text.strip_edges(), name, sha)
	_set_status("Creating…", false)

func _br_delete():
	var sel = br_list.get_selected_items()
	if sel.is_empty(): _set_status("Select branch", true); return
	var bname = branches[sel[0]].get("name", "")
	api.delete_branch(br_owner.text.strip_edges(), br_repo.text.strip_edges(), bname)
	_set_status("Deleting…", false)

func _do_merge():
	var bi = merge_base.selected
	var hi = merge_head.selected
	if bi < 0 or hi < 0: _set_status("Select both", true); return
	var base = branches[bi].get("name", "")
	var head = branches[hi].get("name", "")
	var msg = merge_msg.text.strip_edges()
	if msg == "": msg = "Merge %s into %s" % [head, base]
	api.merge_branches(br_owner.text.strip_edges(), br_repo.text.strip_edges(), base, head, msg)
	_set_status("Merging…", false)

func _is_ignored(path: String) -> bool:
	var fname = path.get_file()
	for ext in IGNORE_EXT:
		if fname.ends_with(ext): return true
	for seg in path.split("/"):
		for d in IGNORE_DIRS:
			if seg == d: return true
	for pattern in custom_ignore:
		if pattern != "" and (path.contains(pattern) or fname == pattern): return true
	return false

func _file_load_remote():
	var o = file_owner.text.strip_edges()
	var r = file_repo.text.strip_edges()
	if o == "" or r == "": _set_status("Owner+repo required", true); return
	var br = "HEAD"
	if file_branch.selected >= 0: br = file_branch.get_item_text(file_branch.selected)
	ctx_branch = br
	file_is_remote = true
	queue_files = []
	_set_status("Loading…", false)
	api.fetch_tree(o, r, br)

func _populate_tree(data):
	files = []
	ignored_files = []
	for item in data.get("tree", []):
		if item is Dictionary and item.get("type", "") == "blob":
			var path = item.get("path", "")
			if _is_ignored(path): ignored_files.append(item)
			else: files.append(item)
	_refresh_tree()
	_set_status("Remote: %d files, %d ignored" % [files.size(), ignored_files.size()], false)

func _file_scan_local():
	var local = local_path.text.strip_edges()
	if local == "": local = "res://"
	file_is_remote = false
	files = []
	ignored_files = []
	queue_files = []
	var dir = DirAccess.open(local)
	if not dir: _set_status("Cannot open", true); return
	_walk(dir, local, local)
	_refresh_tree()
	_set_status("Scanned: %d files, %d ignored" % [files.size(), ignored_files.size()], false)

func _walk(dir: DirAccess, base: String, current: String):
	dir.list_dir_begin()
	var name = dir.get_next()
	while name != "":
		if not name.begins_with("."):
			var full = current.path_join(name)
			if dir.current_is_dir():
				var skip = false
				for ig in IGNORE_DIRS:
					if name == ig: skip = true; break
				if not skip:
					var sub = DirAccess.open(full)
					if sub: _walk(sub, base, full)
			else:
				var rel = full.trim_prefix(base).trim_prefix("/")
				var entry = {"path": rel, "local_full": full, "type": "blob"}
				if _is_ignored(rel): ignored_files.append(entry)
				else: files.append(entry)
		name = dir.get_next()

func _get_source():
	match file_mode:
		0: return files
		1: return queue_files
		2: return ignored_files
	return []

func _refresh_tree():
	file_tree.clear()
	var source = _get_source()
	var dirs = {}
	for item in source:
		if item is Dictionary:
			var path = item.get("path", "")
			var parts = path.split("/")
			var depth = parts.size() - 1
			var folder = ""
			for i in depth:
				folder = folder + "/" + parts[i] if folder != "" else parts[i]
				if not dirs.has(folder):
					dirs[folder] = true
					file_tree.add_item("  ".repeat(i) + "> " + parts[i])
			file_tree.add_item("  ".repeat(depth) + "> " + parts[-1])
	ignore_lbl.text = "%d files | %d ignored | %d queued" % [files.size(), ignored_files.size(), queue_files.size()]

func _get_item_from_idx(idx):
	var source = _get_source()
	var dirs = {}
	var row = 0
	for item in source:
		if item is Dictionary:
			var path = item.get("path", "")
			var parts = path.split("/")
			var depth = parts.size() - 1
			var folder = ""
			for i in depth:
				folder = folder + "/" + parts[i] if folder != "" else parts[i]
				if not dirs.has(folder):
					dirs[folder] = true
					if row == idx: return {}
					row += 1
			if row == idx: return item
			row += 1
	return {}

func _on_file_tap(idx):
	var item = _get_item_from_idx(idx)
	if item.is_empty(): return
	var path = item.get("path", "")
	file_path = path
	file_branch_name = ctx_branch
	file_path_lbl.text = path
	if item.has("local_full"):
		var fa = FileAccess.open(item["local_full"], FileAccess.READ)
		if fa: file_content.text = fa.get_as_text(); file_sha = ""; fa.close()
		else: file_content.text = "(Cannot read)"
	else:
		file_content.text = "Loading…"
		api.fetch_file_meta(file_owner.text.strip_edges(), file_repo.text.strip_edges(), path, file_branch_name)


func _on_file_multi(idx: int, selected: bool):
	var item = _get_item_from_idx(idx)
	if item.is_empty(): return
	var path = item.get("path", "")
	
	var found = -1
	for i in queue_files.size():
		if queue_files[i].get("path", "") == path: 
			found = i
			break
	if selected and found == -1:
		queue_files.append(item)
	elif not selected and found >= 0:
		queue_files.remove_at(found)
		
	ignore_lbl.text = "%d files | %d ignored | %d queued" % [files.size(), ignored_files.size(), queue_files.size()]


func _on_file_tab(tab):
	file_mode = tab
	_refresh_tree()

func _on_right_tab(tab):
	file_content.visible = tab == 0
	queue_list.visible = tab == 1
	if tab == 1:
		queue_list.clear()
		for item in queue_files:
			if item is Dictionary: queue_list.add_item(item.get("path", ""))

func _do_push_one():
	if file_path == "": _set_status("Select file", true); return
	var msg = push_msg.text.strip_edges()
	if msg == "": _set_status("Message required", true); return
	api.push_file(file_owner.text.strip_edges(), file_repo.text.strip_edges(), file_path, msg,
		Marshalls.utf8_to_base64(file_content.text), file_sha, file_branch_name)
	_set_status("Pushing…", false)

func _do_pull_file():
	if file_path == "": _set_status("Select file", true); return
	var local = local_path.text.strip_edges()
	if local == "": local = "res://"
	var dest = local.path_join(file_path.get_file())
	var fa = FileAccess.open(dest, FileAccess.WRITE)
	if not fa: _set_status("Cannot write", true); return
	fa.store_string(file_content.text); fa.close()
	_set_status("Pulled ✓", false)

func _do_push_queue():
	if queue_files.is_empty(): _set_status("Queue empty", true); return
	_start_push(queue_files)

func _do_push_all():
	if files.is_empty(): _set_status("No files", true); return
	_start_push(files)

func _start_push(items):
	var o = file_owner.text.strip_edges()
	var r = file_repo.text.strip_edges()
	var msg = push_msg.text.strip_edges()
	var br = ctx_branch
	if file_branch.selected >= 0: br = file_branch.get_item_text(file_branch.selected)
	if o == "" or r == "": _set_status("Owner+repo required", true); return
	if msg == "": _set_status("Message required", true); return
	var push_files = []
	for item in items:
		if item is Dictionary:
			if item.has("local_full"):
				var fa = FileAccess.open(item["local_full"], FileAccess.READ)
				if fa:
					var raw = fa.get_buffer(fa.get_length()); fa.close()
					push_files.append({"path": item["path"], "content_b64": Marshalls.raw_to_base64(raw)})
			elif item.get("path", "") == file_path and file_path != "":
				push_files.append({"path": file_path, "content_b64": Marshalls.utf8_to_base64(file_content.text)})
	if push_files.is_empty(): _set_status("No files", true); return
	_set_status("Pushing %d files…" % push_files.size(), false)
	pending_push = {"owner": o, "repo": r, "branch": br, "files": push_files, "message": msg}
	api.fetch_branches(o, r)

func _show_ignored():
	ignored_list.clear()
	for item in ignored_files:
		if item is Dictionary: ignored_list.add_item(item.get("path", ""))

func _on_ignored_tap(idx):
	if idx < 0 or idx >= ignored_files.size(): return
	var item = ignored_files[idx]
	file_path = item.get("path", "")
	file_path_lbl.text = file_path
	if item.has("local_full"):
		var fa = FileAccess.open(item["local_full"], FileAccess.READ)
		if fa: file_content.text = fa.get_as_text(); fa.close()

func _do_add_ignore():
	var pattern = ignore_add_input.text.strip_edges()
	if pattern == "": return
	if not custom_ignore.has(pattern): custom_ignore.append(pattern)
	ignore_add_input.text = ""
	var all = files + ignored_files
	files = []; ignored_files = []
	for item in all:
		if item is Dictionary:
			if _is_ignored(item.get("path", "")): ignored_files.append(item)
			else: files.append(item)
	_refresh_tree()
	_set_status("Updated", false)

func _cm_fetch():
	var o = cm_owner.text.strip_edges()
	var r = cm_repo.text.strip_edges()
	if o == "" or r == "": _set_status("Owner+repo required", true); return
	api.fetch_commits(o, r, cm_branch.text.strip_edges(), commits_page)

func _populate_commits(data):
	commits = data
	cm_list.clear()
	for c in data:
		if c is Dictionary:
			var co = {}
			if c.has("commit") and c["commit"] is Dictionary:
				co = c["commit"]
			
			var msg = co.get("message", "")
			var line = msg.split("\n")[0] if "\n" in msg else msg
			if line.length() > 60: 
				line = line.substr(0, 57) + "…"
			
			var sha = str(c.get("sha", ""))
			if sha.length() > 7:
				sha = sha.substr(0, 7)
				
			var author_name = "?"
			var author = co.get("author")
			if author is Dictionary:
				author_name = author.get("name", "?")
				
			cm_list.add_item("[%s] %s — %s" % [sha, line, author_name])
			
	cm_prev.disabled = commits_page <= 1


func _on_commit_selected(idx):
	if idx < 0 or idx >= commits.size(): return
	var c = commits[idx]
	var co = c.get("commit", {})
	cm_detail.text = "[b]%s[/b]\n%s\n\n[url]%s[/url]" % [
		c.get("sha", ""), co.get("message", ""), c.get("html_url", "")]
	diff_view.text = "Loading…"
	api.fetch_commit(cm_owner.text.strip_edges(), cm_repo.text.strip_edges(), c.get("sha", ""))

func _show_diff(data):
	var out = ""
	for f in data.get("files", []):
		if f is Dictionary:
			out += "=== %s\n%s\n" % [f.get("filename", ""), f.get("patch", "(binary)") if f.get("patch") != null else "(binary)"]
	diff_view.text = out if out != "" else "No diff"

func _pr_fetch():
	var o = pr_owner.text.strip_edges()
	var r = pr_repo.text.strip_edges()
	if o == "" or r == "": _set_status("Owner+repo required", true); return
	var state = (["open", "closed", "all"] as Array)[pr_state_opt.selected]
	api.fetch_pulls(o, r, state)

func _populate_prs(data):
	pulls = data
	pr_list.clear()
	for pr in data:
		if pr is Dictionary:
			pr_list.add_item("#%d  %s" % [pr.get("number", 0), pr.get("title", "")])

func _on_pr_selected(idx):
	if idx < 0 or idx >= pulls.size(): return
	var pr = pulls[idx]
	sel_pr = pr.get("number", -1)
	pr_detail.text = "[b]#%d: %s[/b]\n%s → %s\nBy: %s\n\n%s\n\n[url]%s[/url]" % [
		pr.get("number", 0), pr.get("title", ""),
		pr.get("head", {}).get("ref", "?"), pr.get("base", {}).get("ref", "?"),
		pr.get("user", {}).get("login", "?"),
		pr.get("body", "") if pr.get("body") != null else "_No description_",
		pr.get("html_url", "")]

func _do_pr_merge():
	if sel_pr < 0: _set_status("Select PR", true); return
	api.merge_pr(pr_owner.text.strip_edges(), pr_repo.text.strip_edges(), sel_pr, "Merged")
	_set_status("Merging…", false)

func _do_pr_close():
	if sel_pr < 0: _set_status("Select PR", true); return
	api.close_pr(pr_owner.text.strip_edges(), pr_repo.text.strip_edges(), sel_pr)
	_set_status("Closing…", false)

func _do_pr_create():
	var o = pr_owner.text.strip_edges(); var r = pr_repo.text.strip_edges()
	var title = pr_title.text.strip_edges(); var head = pr_head.text.strip_edges()
	var base = pr_base.text.strip_edges()
	if o == "" or r == "" or title == "" or head == "" or base == "": _set_status("All required", true); return
	api.create_pr(o, r, title, pr_body.text, head, base)
	_set_status("Creating…", false)

func _is_fetch():
	var o = is_owner.text.strip_edges()
	var r = is_repo.text.strip_edges()
	if o == "" or r == "": _set_status("Owner+repo required", true); return
	var state = (["open", "closed", "all"] as Array)[is_state_opt.selected]
	api.fetch_issues(o, r, state)

func _populate_issues(data):
	issues = data
	is_list.clear()
	for issue in data:
		if issue is Dictionary:
			is_list.add_item("#%d  %s" % [issue.get("number", 0), issue.get("title", "")])

func _on_issue_selected(idx):
	if idx < 0 or idx >= issues.size(): return
	var issue = issues[idx]
	sel_issue = issue.get("number", -1)
	is_detail.text = "[b]#%d: %s[/b]\nBy: %s\n\n%s\n\n[url]%s[/url]" % [
		issue.get("number", 0), issue.get("title", ""),
		issue.get("user", {}).get("login", "?"),
		issue.get("body", "") if issue.get("body") != null else "_No description_",
		issue.get("html_url", "")]

func _do_issue_close():
	if sel_issue < 0: _set_status("Select issue", true); return
	api.close_issue(is_owner.text.strip_edges(), is_repo.text.strip_edges(), sel_issue)
	_set_status("Closing…", false)

func _do_issue_create():
	var o = is_owner.text.strip_edges(); var r = is_repo.text.strip_edges()
	var title = is_title.text.strip_edges()
	if o == "" or r == "" or title == "": _set_status("Owner, repo, title required", true); return
	api.create_issue(o, r, title, is_body.text)
	_set_status("Creating…", false)

func _on_done(tag, data):
	match tag:
		"user": 
			if data is Dictionary:
				_set_status("Connected as %s" % data.get("login", "?"), false)
				_save_token(api.get_token())
				api.fetch_my_repos(1)
		"repos": 
			if data is Array: _populate_repos(data); _set_status("OK", false)
		"search_repos": 
			if data is Dictionary: _populate_repos(data.get("items", []))
		"create_repo": 
			_set_status("Created ✓", false); api.fetch_my_repos(1)
		"branches": 
			if data is Array: _populate_branches(data)
			if not pending_push.is_empty(): _push_go(data)
		"tree": 
			if data is Dictionary: _populate_tree(data)
		"file_meta": 
			if data is Dictionary:
				file_sha = data.get("sha", "")
				var b64 = data.get("content", "")
				file_content.text = Marshalls.base64_to_utf8(b64.replace("\n", "")) if b64 != "" else "(binary)"
		"push_file": 
			_set_status("Pushed ✓", false)
		"push_commit": 
			pending_push = {}; _set_status("Complete ✓", false)
		"commits": 
			if data is Array: _populate_commits(data)
		"commit_detail": 
			if data is Dictionary: _show_diff(data)
		"pulls": 
			if data is Array: _populate_prs(data)
		"create_pr": 
			_set_status("Created ✓", false); _pr_fetch()
		"merge_pr": 
			_set_status("Merged ✓", false); _pr_fetch()
		"close_pr": 
			_set_status("Closed", false); _pr_fetch()
		"issues": 
			if data is Array: _populate_issues(data)
		"create_issue": 
			_set_status("Created ✓", false); _is_fetch()
		"close_issue": 
			_set_status("Closed", false); _is_fetch()

func _on_fail(tag, msg):
	pending_push = {}
	_set_status("[%s] %s" % [tag, msg], true)

func _push_go(branches_data):
	var push = pending_push
	pending_push = {}
	var br = push.get("branch", "main")
	var sha = ""
	for b in branches_data:
		if b is Dictionary and b.get("name", "") == br:
			sha = b.get("commit", {}).get("sha", "")
			break
	if sha == "": _set_status("Branch not found", true); return
	pending_push = push
	pending_push["parent_sha"] = sha
	api.fetch_commit(push["owner"], push["repo"], sha)

func _continue_push(data):
	if pending_push.is_empty(): return
	var tree_sha = data.get("commit", {}).get("tree", {}).get("sha", "")
	if tree_sha == "": _set_status("Tree not found", true); pending_push = {}; return
	var push = pending_push
	pending_push = {}
	api.push_commit(push["owner"], push["repo"], push["branch"], push["files"], push["message"], push["parent_sha"], tree_sha)

func _on_done_patched(tag, data):
	if tag == "commit_detail" and not pending_push.is_empty() and data is Dictionary:
		_continue_push(data)
	else:
		_on_done(tag, data)

func _set_status(msg, err):
	status_lbl.text = msg
	status_lbl.add_theme_color_override("font_color", Color.TOMATO if err else Color(0.85, 0.85, 0.85, 1))
