% performs tracking of multiple bboxes given a .box file after autobox.m

addpath(genpath('.'));

seqStart = 1;
seqEnd = 46;

for sNum = seqStart:seqEnd
    seq_name = sprintf('self%05d',sNum);
    imDir = sprintf('/home/is/Occlusion Video Data/self shot/%s', seq_name);
    imageList = dir(fullfile(imDir, '*.jpg'));
    imFiles = {imageList.name};
    clear imageList;

    boxdir = fullfile(imDir,'bboxes');
    chunklist = dir(fullfile(boxdir, '*.box'));
    chunkfiles = {chunklist.name};
    clear chunklist;
    
    for chunk_i = 1:1:size(chunkfiles,2)
        [~,chunk_name,~] = fileparts(chunkfiles{chunk_i});
        
        frameBegin = str2num(chunk_name(1:5));
        frameEnd = str2num(chunk_name(7:11));
        
        try
            bboxes = dlmread(fullfile(boxdir,chunkfiles{chunk_i}));
        catch
            bboxes = [];
        end
        
        for bbox_i = 1:1:size(bboxes,1)
            
            % !!! CAREFUL USING THIS SECTION !!!
            % KEEP THIS SECTION COMMENTED UNLESS YOU KNOW WHAT YOU ARE DOING
            % ONLY TO PROCESS FOR .TRACK FILES WHICH DON'T ALREADY EXIST
            % if exist(fullfile(boxdir,sprintf('%s_%03d.track',chunk_name,bbox_i)),'file')==2
            %     fprintf('Skipping %s\n', fullfile(boxdir,sprintf('%s_%03d.track',chunk_name,bbox_i)));
            %     continue
            % end
            % !!! END OF CAREFUL USING THIS SECTION !!!

            bbox = bboxes(bbox_i,:);
            
            initPos = [bbox(2),bbox(1)];
            targetSz = [bbox(4),bbox(3)];

            methods = {'df'}; %,'ccot'}; %,'staple','diagnose','kcf'};
            for mNum = 1:length(methods)
                method = methods{mNum}; 
                debug = false;

                % forward tracking
                [boxes_forward, dists] = doTracking(imDir, imFiles(frameBegin:frameEnd), initPos, targetSz, method);
                
                dlmwrite(fullfile(boxdir,sprintf('%s_%03d.track',chunk_name,bbox_i)),boxes_forward);
                dlmwrite(fullfile(boxdir,sprintf('%s_%03d_%s.dist',chunk_name,bbox_i,method)),dists);
            end
        end
    end
end