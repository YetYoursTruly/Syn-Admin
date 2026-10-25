--Slogan idea: Protecting your ass 24/7

local OWNER = "YetYoursTruly"
local REPO = "SynView"
local BRANCH = "main"

local LOCAL_ROOT = "Syn-Admin"

local AssetFolder = LOCAL_ROOT .. "/Assets"

function SynViewLoading:DownloadRepositoryAssets(force)
    assert(
        isfolder and makefolder and isfile and writefile,
        "Missing filesystem functions (THIS IS A PROBLEM WITH YOUR EXECUTOR)"
    )

    ensureFolder(LOCAL_ROOT)
    targetProgress = 0

    local treeUrl = (
        "https://api.github.com/repos/%s/%s/git/trees/%s?recursive=1"
    ):format(OWNER, REPO, BRANCH)

    local tree = HttpService:JSONDecode(httpGet(treeUrl))
    assert(tree.tree, "GitHub did not return a file tree")

    if tree.truncated then
        warn("[Syn-Admin] GitHub file tree was truncated; some assets may be missing")
    end

    local jobs, skipped, failed = {}, 0, {}

    for _, entry in ipairs(tree.tree) do
        if entry.type == "blob" and entry.path:match("^Assets/") then
            local localPath = LOCAL_ROOT .. "/" .. entry.path
            ensureFolder(localPath:match("^(.*)/[^/]+$"))

            if isfile(localPath) and not force then
                skipped = skipped + 1
            else
                table.insert(jobs, {
                    path = localPath,
                    url = ("https://raw.githubusercontent.com/%s/%s/%s/%s"):format(
                        OWNER, REPO, BRANCH, urlEncodePath(entry.path)
                    ),
                })
            end
        end
    end

    local total = #jobs
    local downloaded = 0

    if total > 0 then
        local nextJob, completed, activeWorkers = 1, 0, 0

        for _ = 1, math.min(CONFIG.DownloadWorkers, total) do
            activeWorkers = activeWorkers + 1

            task.spawn(function()
                while running do
                    local job = jobs[nextJob]
                    if not job then
                        break
                    end
                    nextJob = nextJob + 1

                    local ok, err = pcall(downloadFile, job.url, job.path, true)
                    if ok then
                        downloaded = downloaded + 1
                        print("[SynView] Downloaded: " .. job.path)
                    else
                        table.insert(failed, { path = job.path, error = tostring(err) })
                        warn("[SynView] Failed: " .. job.path .. " - " .. tostring(err))
                    end

                    completed = completed + 1
                    targetProgress = completed / total
                end

                activeWorkers = activeWorkers - 1
            end)
        end

        while activeWorkers > 0 and running do
            task.wait()
        end
    end

    targetProgress = 1

    return {
        Downloaded = downloaded,
        Skipped = skipped,
        Failed = failed,
    }
end
