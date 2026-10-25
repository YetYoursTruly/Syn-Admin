return function(context)
    assert(context and context.PageManager, "Debug context is missing PageManager")
    local pages = context.PageManager:GetPages()
    print(("[Syn-Admin] Debug mode enabled. Registered pages: %d"):format(#pages))
    for index, name in ipairs(pages) do
        print(("[Syn-Admin] Page %d: %s"):format(index, name))
    end
end
