function pimped = pimpmystrings(strings,rgbmap)
if isempty(strings)
    pimped = {};
    return
end
if ischar(strings)
     pimped = [  '<html><DIV bgcolor="', ...
                color2hex(rgbmap), ...
                '"><font color="' blackorwhite(rgbmap) '"><b>', ...
                strings, ...
                '</b></font></DIV></html>' ];
elseif iscell(strings)
    for ind1 = 1:numel(strings)
        clr = rgbmap(ind1,:);
        pimped{ind1} = [  '<html><DIV bgcolor="', ...
                    color2hex(clr), ...
                    '"><font color="' blackorwhite(clr) '"><b>', ...
                    strings{ind1}, ...
                    '</b></font></DIV></html>' ];
    end
end

function output = blackorwhite(RGB)

% Counting the perceptive luminance - human eye favors green color
a = 1 - ( 0.299 * RGB(1) + 0.587 * RGB(2) + 0.114 * RGB(3));

if (a < 0.5)
   output = 'black';
else
   output = 'white';
end