function result = is_touching_border( box, w, h )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

result = false;

if box(1) <= 2 || box(2) <= 2 || box(1)+box(3)>=w || box(2)+box(4)>=h
    result = true;
end

end
