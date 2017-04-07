% creates bboxes for start frame of several overlapping chunks of the video

clear all;

for vid_i = 1:1:46

%% paths

vidname = sprintf('self%05d',vid_i);
viddir = '/home/is/Occlusion Video Data/self shot';
imdir = fullfile(viddir,vidname);

% MOVING EXISTING FILES IN ITS BBOXES FOLDER TP BBOXES_OLD
boxdir = fullfile(imdir,'bboxes');
if exist(boxdir,'dir')~=7
    mkdir(boxdir);
end
% COMMENT THE FOLLOWING IF USING THE !!! CAREFUL USING THIS SECTION !!! SECTION
boxdir_to_move_old = fullfile(imdir,'bboxes_old');
if exist(boxdir_to_move_old,'dir')~=7
    mkdir(boxdir_to_move_old);
end
if length(dir(fullfile(boxdir,'*'))) > 2
    movefile(fullfile(boxdir,'*'), boxdir_to_move_old)
end
% END OF COMMENT THE FOLLOWING IF USING THE !!! CAREFUL USING THIS SECTION !!! SECTION

imlist = dir(fullfile(imdir, '*.jpg'));
imfiles = {imlist.name};
clear imlist;

total_num_im = size(imfiles,2);
chunk_size = 500; % CAN CHANGE THIS
chunk_step_size = 250; % must be less than chunk_size?

if total_num_im-chunk_size < 1
    chunk_end_i = 1;
else
    chunk_end_i = total_num_im-chunk_step_size;
end

%%
for chunk_i = 1:chunk_step_size:chunk_end_i

% !!! CAREFUL USING THIS SECTION !!!
% KEEP THIS SECTION COMMENTED UNLESS YOU KNOW WHAT YOU ARE DOING
% ONLY TO GENERATE MISSING CHUNKS AT THE END WHERE CHUNK SIZE IS SMALLER
% !!! NOTE: COMMENT THE CODE RELATED TO boxdir_to_move_old ABOVE !!!
% if total_num_im-chunk_size < 1
%     end_fr = total_num_im;
% else
%     end_fr = chunk_i+chunk_size-1;
%     if end_fr > total_num_im
%         end_fr = total_num_im;
%     end
% end
% if exist(fullfile(boxdir,sprintf('%05d_%05d.box',chunk_i,end_fr)),'file')==2
% fprintf('Skipping %s\n', fullfile(boxdir,sprintf('%05d_%05d.box',chunk_i,end_fr)));
%     continue
% end
% !!! END OF CAREFUL USING THIS SECTION !!!
    
%% parameters

n = 10; % number of frames to consider
step = 5; % step size when skipping frames
min_patch_size = 50; % patches around smaller features will be forced to be of this size
max_patch_size = 200; % patches around larger features will be forced to be of this size
border = 0.1; % relative thickness of image edge to ignore features in them
variance_threshold = 0.01; % minimum pixel variance for a valid patch
patches_per_video = 10; % maximum number of patches to have per video clip


%% generate keypoints and decriptors

I = cell(n,1); % images (video frames)
k = cell(n,1); % keypoints
d = cell(n,1); % descriptors

for i = 1:1:n
    imfile = fullfile(imdir,sprintf('%s_%05d.jpg',vidname,chunk_i+(i-1)*step));
    I{i} = single(rgb2gray(imread(imfile))) ./ single(255); % single precision and normalized
    [k{i},d{i}] = vl_sift(I{i}); % compute SIFT keypoints and descriptors
end


%% FOR DISPLAY ONLY
% show r random keypoints on jth image

% j = 1;
% r = 50;
% imshow(I{j});
% perm = randperm(size(k{j},2)); % randomize
% sel = perm(1:r); % select r
% h1 = vl_plotframe(k{j}(:,sel)); % one set of circles around keypoints
% h2 = vl_plotframe(k{j}(:,sel)); % another set of circles around keypoints
% set(h1,'color','k','linewidth',3); % black circles
% set(h2,'color','y','linewidth',2); % slightly smaller yellow circles


%% find keypoints in 1st frame that persist over all selected frames

matches = cell(n,1); % matched keypoints
scores = cell(n,1); % matching score (L2 norm of difference between descriptors?)
persist_keypoints = 1:size(k{1},2); % all points in k{1} initially, take intersections later

for i = 2:1:n
    thresh = 1.5; % default anyway; see http://www.vlfeat.org/matlab/vl_ubcmatch.html
    [matches{i},scores{i}] = vl_ubcmatch(d{1},d{i},thresh); % get matches
    persist_keypoints = intersect(persist_keypoints,matches{i}(1,:));
end

persist_keypoints = k{1}(:,persist_keypoints);


%% FOR DISPLAY ONLY
% show persist_keypoints on 1st image

% imshow(I{1});
% h1 = vl_plotframe(persist_keypoints); % one set of circles around keypoints
% h2 = vl_plotframe(persist_keypoints); % another set of circles around keypoints
% set(h1,'color','k','linewidth',3); % black circles
% set(h2,'color','y','linewidth',2); % slightly smaller yellow circles


%% remove invalid/suboptimal keypoints

% to delete features in edges of the image (border on all sides)
to_delete = [];
[h,w] = size(I{1});
for i = 1:1:size(persist_keypoints,2)
    kp_i = persist_keypoints(:,i);
    if kp_i(1) < border * w || kp_i(1) > (1-border) * w || ...
       kp_i(2) < border * h || kp_i(2) > (1-border) * h
        to_delete = [to_delete, i];
    end
end

to_delete = unique(to_delete);
persist_keypoints(:,to_delete) = [];

% to delete overlapping features
to_delete = [];
min_rad = min_patch_size / 2;
for i = 1:1:size(persist_keypoints,2)
    for j = i+1:1:size(persist_keypoints,2)
        kp_i = persist_keypoints(:,i);
        kp_j = persist_keypoints(:,j);
        
        % set radii to min_rad if they are less than that
        if kp_i(3) < min_rad, kp_i(3) = min_rad; end
        if kp_j(3) < min_rad, kp_j(3) = min_rad; end
        
        % using square patches to check overlap:
        % if left edge of ith keypoint falls inside left and right edges of
        % jth keypoint, or vice-versa, AND
        % if top edge of ith keypoint falls inside top and bottom edges of
        % jth keypoint, or vice-versa
        if ((kp_j(1)-kp_j(3) <= kp_i(1)-kp_i(3) && kp_i(1)-kp_i(3) < kp_j(1)+kp_j(3)) || ...
            (kp_i(1)-kp_i(3) <= kp_j(1)-kp_j(3) && kp_j(1)-kp_j(3) < kp_i(1)+kp_i(3))) && ...
           ((kp_j(2)-kp_j(3) <= kp_i(2)-kp_i(3) && kp_i(2)-kp_i(3) < kp_j(2)+kp_j(3)) || ...
            (kp_i(2)-kp_i(3) <= kp_j(2)-kp_j(3) && kp_j(2)-kp_j(3) < kp_i(2)+kp_i(3)))
            % then delete the keypoint with smaller radius
            if kp_i(3) < kp_j(3)
                to_delete = [to_delete, i];
            else
                to_delete = [to_delete, j];
            end
        end
        
        % ALTERNATIVE APPROACH: using circular patches to check overlap
%         dist = sqrt((kp_i(1)-kp_j(1))^2 + (kp_i(2)-kp_j(2))^2);
%         
%         % if distance between centers of ith and jth keypoints is
%         % less than the sum of their radii
%         if dist < kp_i(3) + kp_j(3)
%             % then delete the keypoint with smaller radius
%             if kp_i(3) < kp_j(3)
%                 to_delete = [to_delete, i];
%             else
%                 to_delete = [to_delete, j];
%             end
%         end
    end
end

to_delete = unique(to_delete);
persist_keypoints(:,to_delete) = [];


%% FOR DISPLAY ONLY
% show persist_keypoints on 1st image

% imshow(I{1});
% h1 = vl_plotframe(persist_keypoints); % one set of circles around keypoints
% h2 = vl_plotframe(persist_keypoints); % another set of circles around keypoints
% set(h1,'color','k','linewidth',3); % black circles
% set(h2,'color','y','linewidth',2); % slightly smaller yellow circles


%% make bounding boxes

% copy transposed persist_keypoints
bboxes = persist_keypoints';

% keep a copy of feature sizes for using later
bboxes = [bboxes, bboxes(:,3)];

% apply min/max patch sizes
bboxes(logical([zeros(size(bboxes,1),2),bboxes(:,3)<round(min_patch_size/2)])) = round(min_patch_size/2);
bboxes(logical([zeros(size(bboxes,1),2),bboxes(:,3)>round(max_patch_size/2)])) = round(max_patch_size/2);

% transform and store
bboxes(:,1) = bboxes(:,1) - bboxes(:,3); % x
bboxes(:,2) = bboxes(:,2) - bboxes(:,3); % y
bboxes(:,3) = bboxes(:,3) .* 2; % w
bboxes(:,4) = bboxes(:,3); % h

% round off and cast to int
bboxes = uint16(round(bboxes));


%% discard boxes that DO NOT have enough pixel variance in them

to_delete = [];
for i = 1:1:size(bboxes,1)
    patch = I{1}(bboxes(i,2):bboxes(i,2)+bboxes(i,4)-1,bboxes(i,1):bboxes(i,1)+bboxes(i,3)-1);
    im_var = var(patch(:));
%     text(double(bboxes(i,1))+1,double(bboxes(i,2))+6,sprintf('%0.4f',im_var),'FontSize',6,'FontWeight','bold','Color','r');
    if im_var < variance_threshold
        to_delete = [to_delete,i];
    end
end

to_delete = unique(to_delete);
bboxes(to_delete,:) = [];


%% keep only largest patches_per_video number of boxes/features

if size(bboxes,1) > patches_per_video
    [~,indices] = sort(bboxes(:,5));
    % keep only the required last indices
    bboxes = bboxes(indices(end-patches_per_video+1:end),:);
end

% discard the last column, sorting was its only purpose
bboxes = bboxes(:,1:4);


%% FOR DISPLAY ONLY
% show bounding boxes

imshow(I{1});
for i = 1:1:size(bboxes,1)
    rectangle('Position',bboxes(i,:),...
              'EdgeColor', 'r',...
              'LineStyle','-');
end


%% FOR FIGURE EXPORT ONLY
% export figure

if total_num_im-chunk_size < 1
    end_fr = total_num_im;
else
    end_fr = chunk_i+chunk_size-1;
    if end_fr > total_num_im
        end_fr = total_num_im;
    end
end
export_fig(fullfile(boxdir,sprintf('%05d_%05d.box',chunk_i,end_fr)));


%% export bboxes to a file

if total_num_im-chunk_size < 1
    end_fr = total_num_im;
else
    end_fr = chunk_i+chunk_size-1;
    if end_fr > total_num_im
        end_fr = total_num_im;
    end
end
dlmwrite(fullfile(boxdir,sprintf('%05d_%05d.box',chunk_i,end_fr)),bboxes);


end

end