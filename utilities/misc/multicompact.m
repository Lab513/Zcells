function SVMmodels = multicompact(SVMmodels)

for ind1 = 1:numel(SVMmodels)
    SVMmodels{ind1} = compact(SVMmodels{ind1});
end