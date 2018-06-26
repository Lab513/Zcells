function output = process_subselection(subsel,nbframes)
% Create the frames subselection from the subselection parameters set by
% the user

    switch subsel.type
        case 'all'
            output = 1:nbframes;
        case 'lin'
            output = round(linspace(1,nbframes,subsel.nbframes_linlog));
        case 'log'
            midstack = floor(nbframes/2);
            inferior_nb = floor(subsel.nbframes_linlog/2);
            inferior = midstack + 1 - unique(round(logspace(log10(1),log10(midstack),inferior_nb)));
            superior_nb = subsel.nbframes_linlog - inferior_nb;
            superior = midstack + unique(round(logspace(log10(1),log10(nbframes - midstack),superior_nb)));
            output = [fliplr(inferior) superior];
        case 'custom'
            output = subsel.custom_set;
    end
end