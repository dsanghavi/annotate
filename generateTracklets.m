% generate tracklets from .track files

clear all;

global imFiles;
global arr_tracked_boxes;
global int_start_frame;
global int_end_frame;
global int_track_box_buffer;
global trackletsavedir;
global track_name;
global outputVideo;

seqStart = 1;
seqEnd = 46;

int_track_box_buffer = 50;

for sNum = seqStart:seqEnd
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
        arr_tracked_boxes = dlmread(trackfiles{trackfile_i});
        
        trackletsavedir = fullfile(trackletdir,track_name);
        if exist(trackletsavedir,'dir') ~= 7
            mkdir(trackletsavedir);
        end
        
        int_start_frame = str2num(track_name(1:5));
        int_end_frame = str2num(track_name(7:11));
        
        videofile = fullfile(trackletsavedir,sprintf('%s_trklt.avi',track_name));
        outputVideo = VideoWriter(videofile);
        outputVideo.FrameRate = 30;
        open(outputVideo)
        
        trackfileIteration();
        
        close(outputVideo);
        
        % some clean-up of empty directories/files
        if exist(videofile,'file')==2
            % if videofile exists
            f = dir(videofile);
            if f.bytes == 0
                % if videofile is empty
                rmdir(trackletsavedir,'s');
            end
        elseif exist(trackletsavedir,'dir')==7
            % if videofile doesn't exist but trackletsavedir exists
            rmdir(trackletsavedir,'s');
        end
    end
end
    
function trackfileIteration()
    global imFiles;
    global arr_tracked_boxes;
    global int_start_frame;
    global int_end_frame;
    global int_track_box_buffer;
    global trackletsavedir;
    global track_name;
    global outputVideo;
    
    for int_curr_frame = int_start_frame:1:int_end_frame
        img_curr_frame = imread(imFiles{int_curr_frame});
        trackframe = int_curr_frame - int_start_frame + 1;

        y1 = arr_tracked_boxes(trackframe,2)-int_track_box_buffer;
        y2 = arr_tracked_boxes(trackframe,2)+arr_tracked_boxes(trackframe,4)-1+int_track_box_buffer;
        x1 = arr_tracked_boxes(trackframe,1)-int_track_box_buffer;
        x2 = arr_tracked_boxes(trackframe,1)+arr_tracked_boxes(trackframe,3)-1+int_track_box_buffer;

        if y1>0 && y2<=size(img_curr_frame,1) && x1>0 && x2<=size(img_curr_frame,2)
            tracklet = img_curr_frame(y1:y2,x1:x2,:);
            
            % DISPLAY TRACKLET
            % imshow(tracklet);
            % pause(0.01);
            
            % WRITE TRACKLET TO IMAGE FILE
            tracklet_fname = sprintf('%s_trklt%d.png',track_name,int_curr_frame);
            imwrite(tracklet,fullfile(trackletsavedir,tracklet_fname),'PNG');
            
            % WRITE TO VIDEO AS WELL
            writeVideo(outputVideo,tracklet);
        else
            % TRACKLET HAS GONE OUT OF BOUNDS
            % STOP GENERATING TRACKLETS
            return;
        end
    end
end