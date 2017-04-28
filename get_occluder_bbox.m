% disp('---------------------------------------');

% vid_i = 3;
% chunk_i = 2;
% bbox_i = 3;

% vid_i = 1;
% chunk_i = 1;
% bbox_i = 1;
% 
% vid_i = 26;
% chunk_i = 1;
% bbox_i = 5;
% 
% seq_name = sprintf('self%05d',vid_i);
% imDir = sprintf('/home/is/Occlusion Video Data/self shot/%s', seq_name);
% imageList = dir(fullfile(imDir, '*.jpg'));
% imFiles = {imageList.name};
% clear imageList;
% 
% boxdir = fullfile(imDir,'bboxes');
% chunklist = dir(fullfile(boxdir, '*.box'));
% chunkfiles = {chunklist.name};
% clear chunklist;

% bboxes = dlmread(fullfile(boxdir,chunkfiles{1}));
% [~,chunk_name,~] = fileparts(chunkfiles{chunk_i});
% disp(chunk_name);
% 
% minFrame = str2num(chunk_name(1:5));
% maxFrame = str2num(chunk_name(7:11));

% f_occ = dlmread(fullfile(boxdir,sprintf('%s_%03d.focc',chunk_name,bbox_i)));
% if f_occ<1
%     disp('Try a different file');
% end
% fprintf('f_occ = %d\n',f_occ);
% function [x y w h] = get_occluder_bbox(vid_i,chunk_i,bbox_i,imFiles,boxdir,chunk_name, )


function [x2, y2, w2, h2] = get_occluder_bbox(imDir, imFiles, bbox, bbox_past, bbox_occ, bbox_frame, past_bbox_frame, minFrame)

x = bbox(1);
y = bbox(2);
w = bbox(3);
h = bbox(4);

x_past = bbox_past(1);
y_past = bbox_past(2);
w_past = bbox_past(3);
h_past = bbox_past(4);

% INCREASE BOX SIZE
x = x-floor(w/2);
y = y-floor(h/2);
w = 2*w;
h = 2*h;
% TODO Check if it crosses image boundary?
x_past = x_past-floor(w_past/2);
y_past = y_past-floor(h_past/2);
w_past = 2*w_past;
h_past = 2*h_past;


bbox_left = [x,y,floor(w/2),h];
bbox_right = [x+floor(w/2),y,floor(w/2),h];
bbox_up = [x,y,w,floor(h/2)];
bbox_down = [x,y+floor(h/2),w,floor(h/2)];

bbox_left_past = [x_past,y_past,floor(w_past/2),h_past];
bbox_right_past = [x_past+floor(w_past/2),y_past,floor(w_past/2),h_past];
bbox_up_past = [x_past,y_past,w_past,floor(h_past/2)];
bbox_down_past = [x_past,y_past+floor(h_past/2),w_past,floor(h_past/2)];

frame = imread(fullfile(imDir,imFiles{bbox_frame+minFrame-1}));
frame_past = imread(fullfile(imDir,imFiles{past_bbox_frame+minFrame-1}));

% disp(bbox_frame);
% disp(past_bbox_frame);

% imshow(frame);
% pause(3);
% imshow(frame_past);
% pause(3);

[dist_left_l2] = calc_bbox_distance(bbox_left,bbox_left_past,frame,frame_past);
[dist_right_l2] = calc_bbox_distance(bbox_right,bbox_right_past,frame,frame_past);
[dist_up_l2] = calc_bbox_distance(bbox_up,bbox_up_past,frame,frame_past);
[dist_down_l2] = calc_bbox_distance(bbox_down,bbox_down_past,frame,frame_past);


% Normalize
distances_l2 = [dist_left_l2, dist_right_l2, dist_up_l2, dist_down_l2];
% max_l2 = max(distances_l2);
% norm_l2 = distances_l2/max_l2;
norm_l2 = distances_l2; % lol
% fprintf('NormL2 Distances:   Left %f, Right %f,         Up %f, Down %f\n',norm_l2(1),norm_l2(2),norm_l2(3), norm_l2(4));

% Get direction vector
direction = [norm_l2(1)-norm_l2(2),norm_l2(3)-norm_l2(4)];
norm_dirn = direction./sqrt(sum(direction.^2));

% Get new bbox in the opposite direction
% The bbox should be shifted for frame f_occ. ###
% bbox_occ = box_track(f_occ -minFrame + 1, :);

x = bbox_occ(1);
y = bbox_occ(2);
w = bbox_occ(3);
h = bbox_occ(4);

% Since square boxes,
x2 = round(x - w*norm_dirn(1));
y2 = round(y - h*norm_dirn(2));
h2 = h;
w2 = w;

% imshow(imFiles{bbox_frame-1 + minFrame}); % should be f_occ
% rectangle('Position',[x y h w],...
%           'EdgeColor', 'r',...
%           'LineStyle','-');
% rectangle('Position',[x2 y2 h2 w2],...
%           'EdgeColor', 'g',...
%           'LineStyle','-');
% rectangle('Position',bbox_up,...
%           'EdgeColor', 'y',...
%           'LineStyle','-');
% rectangle('Position',bbox_down,...
%           'EdgeColor', 'b',...
%           'LineStyle','-');
