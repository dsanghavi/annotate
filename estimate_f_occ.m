% given a bbox data (x,y,dists... etc) and given that occlusion will occur
% estimate the frame of occlusion (f_occ)

debug   = false;
display = false;

% debug   = true;
% display = true;

debug_v = 3;
debug_c = 2;
debug_b = 3;

% median_filter_order       = 30;
gaussian_window_size      = 37; % odd
prediction_threshold_neg  = 50;
prediction_threshold_pos  = 10;
peak_prominence_threshold = 0.002;
occ_lag                   = 50; % occlusion lag between doubled box and non-doubled
proximity_threshold       = 3;

seqStart = 1;
seqEnd = 46;

vids_to_ignore = [2, 5, 6, 7, 19, 20, 21, 34, 35]; % enter video ID numbers to ignore

predictions_arr = [];

for sNum = seqStart:seqEnd
    
    if sum(vids_to_ignore==sNum)~=0 || (debug && sNum~=debug_v)
        continue;
    end
    
    if mod(sNum, 10) == 1
        fprintf('\n');
    end
    fprintf(sprintf('%%0%dd ',size(num2str(seqEnd),2)),sNum);
    
    seq_name = sprintf('self%05d',sNum);
    imDir = sprintf('/home/is/Occlusion Video Data/self shot/%s', seq_name);

    boxdir = fullfile(imDir,'bboxes');
    chunklist = dir(fullfile(boxdir, '*.box'));
    chunkfiles = {chunklist.name};
    clear chunklist;
    
    for chunk_i = 1:1:size(chunkfiles,2)
        
        if debug && chunk_i~=debug_c
            continue;
        end

        [~,chunk_name,~] = fileparts(chunkfiles{chunk_i});

        try
            bboxes = dlmread(fullfile(boxdir,chunkfiles{chunk_i}));
        catch
            bboxes = [];
        end
        
        for bbox_i = 1:1:size(bboxes,1)
            
            if debug && bbox_i~=debug_b
                continue;
            end

            marked_f_occ = dlmread(fullfile(boxdir,sprintf('%s_%03d.focc',chunk_name,bbox_i)));

            if marked_f_occ > 0
                arr_dist = dlmread(fullfile(boxdir,sprintf('%s_%03d.4boxdist',chunk_name,bbox_i)));
                arr_dist = arr_dist ./ max(max(arr_dist));
                
                minFrame = str2num(chunk_name(1:5));
                maxFrame = str2num(chunk_name(7:11));
                x = minFrame:1:maxFrame;

                if display
                    f1=figure(1);
                    clf(f1);
                    plot(x,arr_dist(:,1),'r'); hold on;
                    plot(x,arr_dist(:,2),'g'); hold on;
                    plot(x,arr_dist(:,3),'b'); hold on;
                    plot(x,arr_dist(:,4),'k'); hold on;
                    plot(x,arr_dist(:,5),'r--'); hold on;
                    plot(x,arr_dist(:,6),'g--'); hold on;
                    plot(x,arr_dist(:,7),'b--'); hold on;
                    plot(x,arr_dist(:,8),'k--');
                end

                % begin by applying a gaussian filter
                arr_filtered_dist = zeros(size(arr_dist));
                gaussian_filter = gausswin(gaussian_window_size);
                gaussian_filter = gaussian_filter / sum(gaussian_filter);
                for i=1:1:8
%                     arr_filtered_dist(:,i) = medfilt1(arr_dist(:,i),median_filter_order);
                    arr_filtered_dist(:,i) = conv(arr_dist(:,i),gaussian_filter,'same');
                end

                if display
                    f2=figure(2);
                    clf(f2);
                    plot(x,arr_filtered_dist(:,1),'r'); hold on;
                    plot(x,arr_filtered_dist(:,2),'g'); hold on;
                    plot(x,arr_filtered_dist(:,3),'b'); hold on;
                    plot(x,arr_filtered_dist(:,4),'k'); hold on;
                    plot(x,arr_filtered_dist(:,5),'r--'); hold on;
                    plot(x,arr_filtered_dist(:,6),'g--'); hold on;
                    plot(x,arr_filtered_dist(:,7),'b--'); hold on;
                    plot(x,arr_filtered_dist(:,8),'k--');
                end

                % see gradients...
                arr_gradients = zeros(size(arr_dist));
                for i=1:1:8
                    arr_gradients(:,i) = gradient(arr_filtered_dist(:,i));
                end

                if display
                    f3=figure(3);
                    clf(f3);
                    plot(x,arr_gradients(:,1),'r'); hold on;
                    plot(x,arr_gradients(:,2),'g'); hold on;
                    plot(x,arr_gradients(:,3),'b'); hold on;
                    plot(x,arr_gradients(:,4),'k'); hold on;
                    plot(x,arr_gradients(:,5),'r--'); hold on;
                    plot(x,arr_gradients(:,6),'g--'); hold on;
                    plot(x,arr_gradients(:,7),'b--'); hold on;
                    plot(x,arr_gradients(:,8),'k--');
                end

                % get peaks info in gradients
                arr_peak_locs = cell(8,1);
                arr_peak_proms = cell(8,1);
                for i=1:1:8
                    [~,arr_peak_locs{i},~,arr_peak_proms{i}] = findpeaks(arr_gradients(:,i));
                    arr_peak_locs{i} = arr_peak_locs{i}(arr_peak_proms{i}>peak_prominence_threshold);
                    arr_peak_proms{i} = arr_peak_proms{i}(arr_peak_proms{i}>peak_prominence_threshold);
                end

                % find relevant peaks

                % delete peaks in i and i-4 that are too close
%                 for i=5:1:8
%                     for j=1:1:size(arr_peak_locs{i},1)
%                         j_val = arr_peak_locs{i}(j);
%                         for k=1:1:size(arr_peak_locs{i-4},1)
%                             k_val = arr_peak_locs{i-4}(k);
%                             if abs(j_val - k_val) <= proximity_threshold
%                                 arr_peak_locs{i}(j) = 0;
%                                 arr_peak_locs{i-4}(k) = 0;
%                             end
%                         end
%                         arr_peak_locs{i-4} = arr_peak_locs{i-4}(arr_peak_locs{i-4}~=0);
%                         arr_peak_proms{i-4} = arr_peak_proms{i-4}(arr_peak_locs{i-4}~=0);
%                     end
%                     arr_peak_locs{i} = arr_peak_locs{i}(arr_peak_locs{i}~=0);
%                     arr_peak_proms{i} = arr_peak_proms{i}(arr_peak_locs{i}~=0);
%                 end

                % delete peaks in i that are not followed by a peak in i-4 within occ_lag frames
                for i=5:1:8
                    for j=1:1:size(arr_peak_locs{i},1)
                        delete_j = true;
                        j_val = arr_peak_locs{i}(j);
                        for k=1:1:size(arr_peak_locs{i-4},1)
                            k_val = arr_peak_locs{i-4}(k);
                            if k_val - j_val > 0 && k_val - j_val <= occ_lag
                                delete_j = false;
                            end
                        end
                        if delete_j
                            arr_peak_locs{i}(j) = 0;
                        end
                    end
                    arr_peak_locs{i} = arr_peak_locs{i}(arr_peak_locs{i}~=0);
                    arr_peak_proms{i} = arr_peak_proms{i}(arr_peak_locs{i}~=0);
                end

                % delete peaks in i-4 that are not preceded by a peak in i within occ_lag frames
                for i=5:1:8
                    for k=1:1:size(arr_peak_locs{i-4},1)
                        delete_k = true;
                        k_val = arr_peak_locs{i-4}(k);
                        for j=1:1:size(arr_peak_locs{i},1)
                            j_val = arr_peak_locs{i}(j);
                            if k_val - j_val > 0 && k_val - j_val <= occ_lag
                                delete_k = false;
                            end
                        end
                        if delete_k
                            arr_peak_locs{i-4}(k) = 0;
                        end
                    end
                    arr_peak_locs{i-4} = arr_peak_locs{i-4}(arr_peak_locs{i-4}~=0);
                    arr_peak_proms{i-4} = arr_peak_proms{i-4}(arr_peak_locs{i-4}~=0);
                end

                % find peaks in i that are approximately same in at least two but not all four
                potentials = cell(8,1);
                for i=5:1:8
                    potentials{i} = [];
                    for j=1:1:size(arr_peak_locs{i},1)
                        count = 1;
                        j_val = arr_peak_locs{i}(j);
                        for y=5:1:8
                            if i==y
                                continue;
                            end
                            for z=1:1:size(arr_peak_locs{y},1)
                                z_val = arr_peak_locs{y}(z);
                                if abs(j_val - z_val) <= proximity_threshold
                                    count = count + 1;
                                end
                            end
                        end
%                         if count >= 2 %&& count < 4
                            potentials{i} = [potentials{i};j_val];
%                         end
                    end
                end

                predicted_f_occ = Inf;
                for i=5:1:8
                    for j=1:1:size(potentials{i},1)
                        j_val = arr_peak_locs{i}(j);
                        if j_val < predicted_f_occ
                            predicted_f_occ = j_val;
                        end
                    end
                end
                
                predicted_f_occ = predicted_f_occ + minFrame - 1;
                
                predictions_arr = [predictions_arr; sNum, chunk_i, bbox_i, marked_f_occ, predicted_f_occ, marked_f_occ-predicted_f_occ];
                
            end

        end
    end
end

fprintf('\n\n');

% fprintf('median_filter_order           = %d\n',median_filter_order);
fprintf('prediction_threshold_pos      = %d\n',prediction_threshold_pos);
fprintf('prediction_threshold_neg      = %d\n',prediction_threshold_neg);
fprintf('peak_prominence_threshold     = %f\n',peak_prominence_threshold);
fprintf('occ_lag                       = %d\n',occ_lag);
fprintf('proximity_threshold           = %d\n\n',proximity_threshold);

acc = sum((predictions_arr(:,6)>=-prediction_threshold_pos) .* (predictions_arr(:,6)<=prediction_threshold_neg))/size(predictions_arr,1);
fprintf('Accuracy: %f\n\n', acc);