local function sort(list, criterion)
    for i = 2, #list do
        local key = list[i]
        local j = i - 1

        while j >= 1 and criterion(list[j]) > criterion(key) do
            list[j + 1] = list[j]
            j = j - 1
        end

        list[j + 1] = key
    end
end

return sort
