function dist_l2 = calc_bbox_distance(bbox,bbox_past,frame,frame_past)
    %% returns the L2 distance of the bboxes in 2 frames
    im1 = im2double(imcrop(frame,bbox));
    im2 = im2double(imcrop(frame_past,bbox_past));
    
%     figure(1);
%     imshow(im1);
%     pause(3);
%     figure(2);
%     imshow(im2);
%     pause(3);

    
    
%     h1 = imhist(im1); % this will have default bins 256
%     h2 = imhist(im2); % this will have default bins 256 
%     dist_hist = sqrt(sum((h1-h2).^2))/(size(im1,1)*size(im1,2));
%     dist
    %disp(dist);
    
    big=8; % HAS TO BE EVEN % PREVIOUSLY USED 8 TO OBTAIN OCCLUDER BOX
    small=big/2;
    
    [hh,ww,~] = size(im1);
    if hh > ww
        n_h = big;
        n_w = small;
        avg1 = zeros(8,4,3);
        avg2 = zeros(8,4,3);
    elseif ww > hh
        n_h = small;
        n_w = big;
        avg1 = zeros(4,8,3);
        avg2 = zeros(4,8,3);
    end
    
    for hi = 1:1:n_h
        for wi = 1:1:n_w
            patch_start_h = (hi-1) * round(hh/n_h) + 1;
            patch_end_h = hi * round(hh/n_h);
            patch_start_w = (wi-1) * round(ww/n_w) + 1;
            patch_end_w = wi * round(ww/n_w);
            if patch_end_h > hh
                patch_end_h = hh;
            end
            if patch_end_w > ww
                patch_end_w = ww;
            end
            avg1(hi,wi,:) = mean(mean(im1(patch_start_h:patch_end_h,patch_start_w:patch_end_w,:)));
            avg2(hi,wi,:) = mean(mean(im2(patch_start_h:patch_end_h,patch_start_w:patch_end_w,:)));
        end
    end
    
%     dist_l2 = sqrt(sum(sum(sum((im1-im2).^2))))/(size(im1,1)*size(im1,2));
    dist_l2 = sqrt(sum(sum(sum((avg1-avg2).^2))))/(big*small);
    end