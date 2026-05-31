local function sort(list, criterion)
    return table.sort(list, function(a, b)
        return criterion(a) > criterion(b)
    end)
end

return sort
