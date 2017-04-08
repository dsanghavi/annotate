% generate tracklets from .track files

clear all;

global imDir;
global imFiles;
global arr_tracked_boxes;
global int_start_frame;
global int_end_frame;
global int_track_box_buffer;
global trackletsavedir;
global track_name;
global outputVideo;
global bool_generate_video;
global bool_generate_images;
global bool_display_images;

seqStart = 1;
seqEnd = 46;

int_track_box_buffer    = 50; % CHANGED to +50% of box size, upto max of 50

bool_generate_video     = true;
bool_generate_images    = true;
bool_display_images     = false;

for sNum = seqStart:seqEnd
    disp(sNum);
    seq_name = sprintf('self%05d',sNum);
    imDir = sprintf('/home/is/Occlusion Video Data/self shot/%s', seq_name);
    imageList = dir(fullfile(imDir, '*.jpg'));
    imFiles = {imageList.name};
    clear imageList;

    boxdir = fullfile(imDir,'bboxes');
    tracklist = dir(fullfile(boxdir, '*.track'));
    trackfiles = {tracklist.name};
    clear tracklist;
    
    trackletdir = fullfile(boxdir,'tracklets');
    if exist(trackletdir,'dir') ~= 7
        mkdir(trackletdir);
    end
    
    for trackfile_i = 1:1:size(trackfiles,2)
        [~,track_name,~] = fileparts(trackfiles{trackfile_i});
        arr_tracked_boxes = dlmread(fullfile(boxdir,trackfiles{trackfile_i}));
        
        trackletsavedir = fullfile(trackletdir,track_name);
        if exist(trackletsavedir,'dir') ~= 7
            mkdir(trackletsavedir);
        end
        
        int_start_frame = str2num(track_name(1:5));
        int_end_frame = str2num(track_name(7:11));
        
        if bool_generate_video
            videofile = fullfile(trackletsavedir,sprintf('%s_trklt.avi',track_name));
            outputVideo = VideoWriter(videofile);
            outputVideo.FrameRate = 30;
            open(outputVideo)
        end
        
        trackfileIteration();
        
        if bool_generate_video
            close(outputVideo);
        end
        
        % some clean-up of empty directories/files
        if exist(videofile,'file')==2
            % if videofile exists
            if bool_generate_video
                f = dir(videofile);
                if f.bytes == 0
                    % if videofile is empty
                    rmdir(trackletsavedir,'s');
                end
            end
        elseif exist(trackletsavedir,'dir')==7
            % if videofile doesn't exist but trackletsavedir exists
            if bool_generate_video || bool_generate_images
                if length(dir(fullfile(trackletsavedir,'*'))) == 2
                    % if trackletsavedir is empty
                    rmdir(trackletsavedir,'s');
                end
            end
        end
    end
end
    
function trackfileIteration()
    global imDir;
    global imFiles;
    global arr_tracked_boxes;
    global int_start_frame;
    global int_end_frame;
    global int_track_box_buffer;
    global trackletsavedir;
    global track_name;
    global outputVideo;
    global bool_generate_video;
    global bool_generate_images;
    global bool_display_images;
    
    for int_curr_frame = int_start_frame:1:int_end_frame
        img_curr_frame = imread(fullfile(imDir,imFiles{int_curr_frame}));
        trackframe = int_curr_frame - int_start_frame + 1;
        
        int_track_box_buffer = round(((arr_tracked_boxes(trackframe,3) + arr_tracked_boxes(trackframe,4)) / 2) * 0.5 + 0.49);
        if int_track_box_buffer > 50
            int_track_box_buffer = 50;
        end

        y1 = arr_tracked_boxes(trackframe,2)-int_track_box_buffer;
        y2 = arr_tracked_boxes(trackframe,2)+arr_tracked_boxes(trackframe,4)-1+int_track_box_buffer;
        x1 = arr_tracked_boxes(trackframe,1)-int_track_box_buffer;
        x2 = arr_tracked_boxes(trackframe,1)+arr_tracked_boxes(trackframe,3)-1+int_track_box_buffer;

        if y1>0 && y2<=size(img_curr_frame,1) && x1>0 && x2<=size(img_curr_frame,2)
            tracklet = img_curr_frame(y1:y2,x1:x2,:);
            
            if bool_display_images
                % DISPLAY TRACKLET
                imshow(tracklet);
                pause(0.005);
            end
            
            if bool_generate_images
                % WRITE TRACKLET TO IMAGE FILE
                tracklet_fname = sprintf('%s_trklt%05d.png',track_name,int_curr_frame);
                imwrite(tracklet,fullfile(trackletsavedir,tracklet_fname),'PNG');
            end
            
            if bool_generate_video
                % WRITE TO VIDEO AS WELL
                writeVideo(outputVideo,tracklet);
            end
        else
            % TRACKLET HAS GONE OUT OF BOUNDS
            % STOP GENERATING TRACKLETS
            return;
        end
    end
end