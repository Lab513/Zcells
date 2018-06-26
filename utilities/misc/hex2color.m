function [color] = hex2color(colorstr)

% Remove non-valid/interesting characters
colorstr(~ismember(colorstr,['A':'F' 'a':'f' '0':'9' 'rgcmykw'])) = '';

if numel(colorstr) == 1;
    switch colorstr
        case 'r'
            color = [1 0 0 ]; 
        case 'g'
            color = [0 1 0 ];
        case 'b'
            color = [0 0 1 ];
        case 'c'
            color = [0 1 1 ];
        case 'm'
            color = [1 0 1 ];
        case 'y'
            color = [1 1 0 ];
        case 'k'
            color = [0 0 0 ];
        case 'w'
            color = [1 1 1 ];
        otherwise
            error(['Unknown color: ' colorstr]);
    end
elseif numel(colorstr) == 6 % Hex case
    color = (double(hex2dec({colorstr(1:2),colorstr(3:4),colorstr(5:6)}))/255)';
else
    error(['Unknown color: ' colorstr]);
end


