
debug = false;

if_use_minus_something = false; % to use minus something frame instead of first to compare
compare_past_by = 20; % matter only if if_use_minus_something is true

pad = 100; % zero padding to manage doubled box going out of bounds

seqStart = 1;
seqEnd = 46;

if debug
    seqEnd = seqStart;
end

%%
for sNum = seqStart:seqEnd
    
    if mod(sNum, 10) == 1
        fprintf('\n');
    end
    fprintf('%02d ',sNum);
    
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
            if bbox_i ~= 4 && debug
                continue;
            end
            
            methods = {'df'}; %,'ccot'}; %,'staple','diagnose','kcf'};
            for mNum = 1:length(methods)
                method = methods{mNum};

                trackboxes = dlmread(fullfile(boxdir,sprintf('%s_%03d.track',chunk_name,bbox_i)));

                im_dists = zeros(size(trackboxes,1),2*size(trackboxes,2));
                               
                % FOR FRAME TO COMPARE WITH
                bbox_first = trackboxes(1,:);

                frame_first = imread(fullfile(imDir,imFiles{minFrame}));
                frame_first = padarray(frame_first, [pad,pad], 0, 'both');

                x_first = bbox_first(1) + pad;
                y_first = bbox_first(2) + pad;
                w_first = bbox_first(3);
                h_first = bbox_first(4);

                x_first_doubled = x_first-floor(w_first/2);
                y_first_doubled = y_first-floor(h_first/2);
                w_first_doubled = 2*w_first;
                h_first_doubled = 2*h_first;

                bbox_left_first = [x_first,y_first,floor(w_first/2),h_first];
                bbox_right_first = [x_first+floor(w_first/2),y_first,floor(w_first/2),h_first];
                bbox_up_first = [x_first,y_first,w_first,floor(h_first/2)];
                bbox_down_first = [x_first,y_first+floor(h_first/2),w_first,floor(h_first/2)];

                bbox_left_first_doubled = [x_first_doubled,y_first_doubled,floor(w_first_doubled/2),h_first_doubled];
                bbox_right_first_doubled = [x_first_doubled+floor(w_first_doubled/2),y_first_doubled,floor(w_first_doubled/2),h_first_doubled];
                bbox_up_first_doubled = [x_first_doubled,y_first_doubled,w_first_doubled,floor(h_first_doubled/2)];
                bbox_down_first_doubled = [x_first_doubled,y_first_doubled+floor(h_first_doubled/2),w_first_doubled,floor(h_first_doubled/2)];
                
                for frame_i = minFrame:1:maxFrame

                    % FOR FRAME TO COMPARE (I.E. CURRENT)
                    bbox = trackboxes(frame_i-minFrame+1,:);
                    
                    frame = imread(fullfile(imDir,imFiles{frame_i}));
                    frame = padarray(frame, [pad,pad], 0, 'both');
                    
                    x = bbox(1) + pad;
                    y = bbox(2) + pad;
                    w = bbox(3);
                    h = bbox(4);

                    % INCREASE BOX SIZE
                    x_doubled = x-floor(w/2);
                    y_doubled = y-floor(h/2);
                    w_doubled = 2*w;
                    h_doubled = 2*h;

                    bbox_left  = [x,            y,            floor(w/2), h];
                    bbox_right = [x+floor(w/2), y,            floor(w/2), h];
                    bbox_up    = [x,            y,            w,          floor(h/2)];
                    bbox_down  = [x,            y+floor(h/2), w,          floor(h/2)];
                    
                    bbox_left_doubled = [x_doubled,y_doubled,floor(w_doubled/2),h_doubled];
                    bbox_right_doubled = [x_doubled+floor(w_doubled/2),y_doubled,floor(w_doubled/2),h_doubled];
                    bbox_up_doubled = [x_doubled,y_doubled,w_doubled,floor(h_doubled/2)];
                    bbox_down_doubled = [x_doubled,y_doubled+floor(h_doubled/2),w_doubled,floor(h_doubled/2)];

                    dist_left_l2 = calc_bbox_distance(bbox_left,bbox_left_first,frame,frame_first);
                    dist_right_l2 = calc_bbox_distance(bbox_right,bbox_right_first,frame,frame_first);
                    dist_up_l2 = calc_bbox_distance(bbox_up,bbox_up_first,frame,frame_first);
                    dist_down_l2 = calc_bbox_distance(bbox_down,bbox_down_first,frame,frame_first);
                    
                    dist_left_l2_doubled = calc_bbox_distance(bbox_left_doubled,bbox_left_first_doubled,frame,frame_first);
                    dist_right_l2_doubled = calc_bbox_distance(bbox_right_doubled,bbox_right_first_doubled,frame,frame_first);
                    dist_up_l2_doubled = calc_bbox_distance(bbox_up_doubled,bbox_up_first_doubled,frame,frame_first);
                    dist_down_l2_doubled = calc_bbox_distance(bbox_down_doubled,bbox_down_first_doubled,frame,frame_first);
                    
                    im_dists(frame_i-minFrame+1, :) = [dist_left_l2, dist_right_l2, dist_up_l2, dist_down_l2, dist_left_l2_doubled, dist_right_l2_doubled, dist_up_l2_doubled, dist_down_l2_doubled];
                end
                
                dlmwrite(fullfile(boxdir,sprintf('%s_%03d.4boxdist',chunk_name,bbox_i)),im_dists);
            end
        end
    end
end

fprintf('\n\n');

%% plot
if debug
    x = minFrame:1:maxFrame;

    plot(x,im_dists(:,1),'r'); hold on;
    plot(x,im_dists(:,2),'g'); hold on;
    plot(x,im_dists(:,3),'b'); hold on;
    plot(x,im_dists(:,4),'k'); hold on;
    plot(x,im_dists(:,5),'r--'); hold on;
    plot(x,im_dists(:,6),'g--'); hold on;
    plot(x,im_dists(:,7),'b--'); hold on;
    plot(x,im_dists(:,8),'k--');
end