function colorstr = color2hex(rgbcolor)

colorstr = '#';
for ind1 = 1:3
    colorstr = [colorstr dec2hex(round(255*rgbcolor(ind1)),2)];
end