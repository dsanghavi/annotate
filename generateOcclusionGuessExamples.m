% This script will generate clips with two initial bounding boxes on
% patches. One patch will eventually occlude the other.

debug = false;

seqStart = 1;
seqEnd = 46;

if debug
    seqEnd = seqStart;
end

%%
for sNum = seqStart:seqEnd
    seq_name = sprintf('self%05d',sNum);
    imDir = sprintf('/home/is/Occlusion Video Data/self shot/%s', seq_name);
    imageList = dir(fullfile(imDir, '*.jpg'));
    imFiles = {imageList.name};
    clear imageList;

    [h, w, ~] = size(imread(fullfile(imDir,imFiles{1})));
    
    boxdir = fullfile(imDir,'bboxes');
    chunklist = dir(fullfile(boxdir, '*.box'));
    chunkfiles = {chunklist.name};
    clear chunklist;
    
    for chunk_i = 1:1:size(chunkfiles,2)
        
        % DEBUG; REMOVE LATER
        if chunk_i ~= 2 && debug
            continue;
        end
        
        [~,chunk_name,~] = fileparts(chunkfiles{chunk_i});
        
        minFrame = str2num(chunk_name(1:5));
        maxFrame = str2num(chunk_name(7:11));
        
        try
            bboxes = dlmread(fullfile(boxdir,chunkfiles{chunk_i}));
        catch
            bboxes = [];
        end
        
        for bbox_i = 1:1:size(bboxes,1)
            
            % DEBUG; REMOVE LATER
            if bbox_i ~= 3 && debug
                continue;
            end
            
            methods = {'df'}; %,'ccot'}; %,'staple','diagnose','kcf'};
            for mNum = 1:length(methods)
                method = methods{mNum};

                f_occ = dlmread(fullfile(boxdir,sprintf('%s_%03d.focc',chunk_name,bbox_i)));
                
                if f_occ > 0
%                     dist_list = dlmread(fullfile(boxdir,sprintf('%s_%03d_%s.dist',chunk_name,bbox_i,method)));
%                     dist_list = [0; dist_list];
                    
%                     dist_f_occ = dist_list(f_occ - minFrame + 1);
%                     min_numPostOccFrames = 100;
%                     max_dist_within_numPostOccFrames = 0;
%                     for fr_i = f_occ:1:maxFrame
%                         if fr_i > f_occ + min_numPostOccFrames
%                             break;
%                         end
%                         if dist_list(fr_i - minFrame + 1) > max_dist_within_numPostOccFrames
%                             max_dist_within_numPostOccFrames = dist_list(fr_i - minFrame + 1);
%                             numPostOccFrames = fr_i - f_occ;
%                         end
%                         if dist_list(fr_i - minFrame + 1) > 3 * dist_f_occ
%                             numPostOccFrames = fr_i - f_occ;
%                             break;
%                         end
%                     end
                    
                    numPostOccFrames = 0;
                    
                    frameBegin = f_occ - 100;
                    if frameBegin < minFrame
                        frameBegin = minFrame;
                    end
                    frameEnd = f_occ + numPostOccFrames;
                    if frameEnd > maxFrame
                        frameEnd = maxFrame;
                    end

%                     bbox = bboxes(bbox_i,:);

                    boxes_forward = dlmread(fullfile(boxdir,sprintf('%s_%03d.track',chunk_name,bbox_i)));

                    % Generate 2nd bbox by comparing l2 distance between
                    % bboxes of 2 frames
                    bbox_frame = f_occ-0-minFrame+1; % Dont change. Otherwise, read bbox for f_occ below. ###
                    past_bbox_frame = f_occ - 20 - minFrame+1;
%                     paster_bbox_frame = f_occ - 20 - minFrame+1;
                    if past_bbox_frame<1
%                         disp('This shouldnt be printed');
                        past_bbox_frame=1;
                    end  

%                     box_track = dlmread(fullfile(boxdir,sprintf('%s_%03d.track',chunk_name,bbox_i)));

                    bbox_occ = boxes_forward(f_occ-minFrame+1, :);
                    bbox_curr = boxes_forward(bbox_frame, :);
                    bbox_past = boxes_forward(past_bbox_frame, :);

                    [x2, y2, w2, h2] = get_occluder_bbox(imDir, imFiles, bbox_curr, bbox_past, bbox_occ, bbox_frame, past_bbox_frame, minFrame);
%                     disp(bbox);
                    bbox = [x2 y2 w2 h2];
                    
%                     imshow(imFiles{f_occ});
%                     rectangle('Position',boxes_forward(f_occ-minFrame+1,:),...
%                               'EdgeColor', 'r',...
%                               'LineStyle','-',...
%                               'LineWidth',3);
%                     rectangle('Position',bbox,...
%                               'EdgeColor', 'g',...
%                               'LineStyle','-',...
%                               'LineWidth',3);
%                     pause(10);
                    
%                     bbox = boxes_forward(frameEnd - minFrame + 1, :);

%                     imshow(imFiles{frameEnd});
%                     rectangle('Position',bbox,...
%                               'EdgeColor', 'r',...
%                               'LineStyle','-');
%                     pause(1);





                    initPos = [bbox(2),bbox(1)];
                    targetSz = [bbox(4),bbox(3)];

%                     disp(frameEnd);
%                     disp(f_occ);
%                     imshow(imFiles{frameEnd});
%                     pause(10);
                    
                    % reverse tracking
                    revImFiles = flip(imFiles(frameBegin:frameEnd),2);
                    [boxes_reverse, dists] = doTracking(imDir, revImFiles, initPos, targetSz, method);

                    % reverse boxes_reverse
                    boxes_reverse = flip(boxes_reverse);
                    boxes_forward = boxes_forward(frameBegin - minFrame + 1:frameEnd - minFrame + 1, :);
                    
                    % checks for boxes touching borders
                    frameBeginAlt = minFrame;
                    frameEndAlt = maxFrame;
                    frameBeginDecided = false;
                    frameEndDecided = false;
                    for j = 1:1:size(boxes_reverse,1)
                        if ~frameBeginDecided && ~is_touching_border(boxes_reverse(j,:), w, h)
                            frameBeginAlt = j - 1 + minFrame;
                            frameBeginDecided = true;
                        end
                        if ~frameEndDecided && is_touching_border(boxes_forward(j,:), w, h)
                            frameEndAlt = j - 1 + minFrame - 1;
                            frameEndDecided = true;
                        end
                    end
                    
                    if frameBegin < frameBeginAlt
                        frameBegin = frameBeginAlt;
                    end
                    if frameEnd > frameEndAlt
                        frameEnd = frameEndAlt;
                    end
                    
                    if frameBegin < frameEnd
                        dlmwrite(fullfile(boxdir,sprintf('%s_%03d_%05d_%05d.revtrack',chunk_name,bbox_i,frameBegin,frameEnd)),boxes_reverse);
                        dlmwrite(fullfile(boxdir,sprintf('%s_%03d_%05d_%05d.fortrack',chunk_name,bbox_i,frameBegin,frameEnd)),boxes_forward);
                    end
                end
            end
        end
    end
end



%% display
if debug %|| true
    for sNum = seqStart:seqEnd
        seq_name = sprintf('self%05d',sNum);
        imDir = sprintf('/home/is/Occlusion Video Data/self shot/%s', seq_name);
        imageList = dir(fullfile(imDir, '*.jpg'));
        imFiles = {imageList.name};
        clear imageList;

        boxdir = fullfile(imDir,'bboxes');
        fortrackfileslist = dir(fullfile(boxdir, '*.fortrack'));
        fortrackfiles = {fortrackfileslist.name};
        clear fortrackfileslist;

        for fortrack_i = 1:1:size(fortrackfiles,2)
            [~,fortrackfilename,~] = fileparts(fortrackfiles{fortrack_i});

            fortrackfile = fullfile(boxdir,sprintf('%s.fortrack',fortrackfilename));
            fortrackboxes = dlmread(fortrackfile);
            revtrackfile = fullfile(boxdir,sprintf('%s.revtrack',fortrackfilename));
            revtrackboxes = dlmread(revtrackfile);

            for i = 1:2:size(revtrackboxes,1)
                imshow(imFiles{i-1+str2num(fortrackfilename(17:21))}); % take care of index numbers
                rectangle('Position',fortrackboxes(i,:),...
                          'EdgeColor', 'r',...
                          'LineStyle','-',...
                          'LineWidth',3);
                rectangle('Position',revtrackboxes(i,:),...
                          'EdgeColor', 'g',...
                          'LineStyle','-',...
                          'LineWidth',3);
                pause(0.03);
            end

            pause(3);
        end
    end
end