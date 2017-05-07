% This script will generate clips with two initial bounding boxes on
% patches. One patch will eventually occlude the other.

debug = true;

pad = 0;

seqStart = 12;
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

%     [h, w, ~] = size(imread(fullfile(imDir,imFiles{1})));
    
    boxdir = fullfile(imDir,'bboxes');
    chunklist = dir(fullfile(boxdir, '*.box'));
    chunkfiles = {chunklist.name};
    clear chunklist;
    
    for chunk_i = 1:1:size(chunkfiles,2)
        
        % DEBUG; REMOVE LATER
        if chunk_i ~= 1 && debug
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

                trackboxes = dlmread(fullfile(boxdir,sprintf('%s_%03d.track',chunk_name,bbox_i)));

                im_dists = zeros(size(trackboxes));
                
                bbox_first = trackboxes(1,:);
                
                frame_first = imread(fullfile(imDir,imFiles{minFrame}));
                frame_first = padarray(frame_first, [pad,pad], 0, 'both');
                
                x_first = bbox_first(1);
                y_first = bbox_first(2);
                w_first = bbox_first(3);
                h_first = bbox_first(4);

                x_first = x_first-floor(w_first/2) + pad;
                y_first = y_first-floor(h_first/2) + pad;
                w_first = 2*w_first;
                h_first = 2*h_first;
                % TODO Check if it crosses image boundary?

                bbox_left_first = [x_first,y_first,floor(w_first/2),h_first];
                bbox_right_first = [x_first+floor(w_first/2),y_first,floor(w_first/2),h_first];
                bbox_up_first = [x_first,y_first,w_first,floor(h_first/2)];
                bbox_down_first = [x_first,y_first+floor(h_first/2),w_first,floor(h_first/2)];

                for frame_i = minFrame+1:1:maxFrame
                    bbox = trackboxes(frame_i-minFrame+1,:);
                    
                    frame = imread(fullfile(imDir,imFiles{frame_i-minFrame+1}));
                    frame = padarray(frame, [pad,pad], 0, 'both');
                    
                    x = bbox(1);
                    y = bbox(2);
                    w = bbox(3);
                    h = bbox(4);

                    % INCREASE BOX SIZE
                    x = x-floor(w/2) + pad;
                    y = y-floor(h/2) + pad;
                    w = 2*w;
                    h = 2*h;
                    % TODO Check if it crosses image boundary?

                    bbox_left = [x,y,floor(w/2),h];
                    bbox_right = [x+floor(w/2),y,floor(w/2),h];
                    bbox_up = [x,y,w,floor(h/2)];
                    bbox_down = [x,y+floor(h/2),w,floor(h/2)];

                    dist_left_l2 = calc_bbox_distance(bbox_left,bbox_left_first,frame,frame_first);
                    dist_right_l2 = calc_bbox_distance(bbox_right,bbox_right_first,frame,frame_first);
                    dist_up_l2 = calc_bbox_distance(bbox_up,bbox_up_first,frame,frame_first);
                    dist_down_l2 = calc_bbox_distance(bbox_down,bbox_down_first,frame,frame_first);
                    
                    im_dists(frame_i-minFrame+1, :) = [dist_left_l2, dist_right_l2, dist_up_l2, dist_down_l2];
                end
            end
        end
    end
end


%% plot
x = minFrame:1:maxFrame;

plot(x,im_dists(:,1),'Color','r'); hold on;
plot(x,im_dists(:,2),'Color','g'); hold on;
plot(x,im_dists(:,3),'Color','b'); hold on;
plot(x,im_dists(:,4),'Color','k');