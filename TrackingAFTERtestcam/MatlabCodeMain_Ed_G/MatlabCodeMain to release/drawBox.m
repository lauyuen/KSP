function  im = drawBox(im, Centres)
w = 10;
h = 20;

[ly, lx] = size(im);

%color = [255, 255, 0];

color = [0, 0, 255];

if isempty(Centres)
    return;
end

Centres = Centres(:, 1:2);

ind = Centres(:, 1) <= w | Centres(:, 2) <= h | max(Centres(:, 1))>= lx-w-1 | max(Centres(:, 2))>= ly-h-1;


Centres = Centres(~ind, :);
if isempty(Centres)
    return;
end


for i = 1:size(Centres, 1)
    
    x = Centres(i, 1);
    y = Centres(i, 2);
    for j = 1:3
        im(y-h-1:y-h+1, x-w+1:x+w, j) = color(j);
        im(y+h-1:y+h+1, x-w+1:x+w, j) = color(j);
        im(y-h+1:y+h, x-w-1:x-w+1, j) = color(j);
        im(y-h+1:y+h, x+w-1:x+w+1, j) = color(j);
    end
end

