
debug = false;

chunk_time_size = 500;

seqStart = 1;
seqEnd = 46;

if debug
    seqEnd = seqStart;
end

%%
datafeatures = []; % empty
datanames = []; % empty
datalabels = []; % empty

for sNum = seqStart:seqEnd
    
    if mod(sNum, 10) == 1
        fprintf('\n');
    end
    fprintf(sprintf('%%0%dd ',size(num2str(seqEnd),2)),sNum);
    
    seq_name = sprintf('self%05d',sNum);
    imDir = sprintf('/home/is/Occlusion Video Data/self shot/%s', seq_name);
%     imageList = dir(fullfile(imDir, '*.jpg'));
%     imFiles = {imageList.name};
%     clear imageList;

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
        
%         minFrame = str2num(chunk_name(1:5));
%         maxFrame = str2num(chunk_name(7:11));
        
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
            
            trackboxes = dlmread(fullfile(boxdir,sprintf('%s_%03d.track',chunk_name,bbox_i)));
            boxdists = dlmread(fullfile(boxdir,sprintf('%s_%03d.4boxdist',chunk_name,bbox_i)));
            dfdists = dlmread(fullfile(boxdir,sprintf('%s_%03d_df.dist',chunk_name,bbox_i)));
            dfdists = [0; dfdists];
            
            data = [trackboxes(:,1:2), boxdists, dfdists];
            
            if size(data,1) < chunk_time_size
                size_remaining = chunk_time_size - size(data,1);
                zeros_to_concat = zeros(size_remaining,size(data,2));
                data = [data; zeros_to_concat];
            elseif size(data,1) > chunk_time_size
                % something's wrong!
                fprintf('Invalid data size. Video: %s, Chunk: %s, Bbox: %d', seq_name, chunk_name, bbox_i);
            end
            
            datafeatures = [datafeatures; data(:)'];
            datanames = [datanames; [sNum, chunk_i, bbox_i]];
            
            focc = dlmread(fullfile(boxdir,sprintf('%s_%03d.focc',chunk_name,bbox_i)));
            if focc > 0
                focc = 1;
            elseif focc == -1
                focc = 2;
            elseif focc == -2
                focc = 3;
            end
            datalabels = [datalabels; focc];
        end
    end
end

[~,name,~] = fileparts(fileparts(imDir));
if name == 'self shot'
    dlmwrite(fullfile(fileparts(imDir),'self.datafeatures'),datafeatures);
    dlmwrite(fullfile(fileparts(imDir),'self.datanames'),datanames);
    dlmwrite(fullfile(fileparts(imDir),'self.datalabels'),datalabels);
elseif name == 'from web'
    dlmwrite(fullfile(fileparts(imDir),'web.datafeatures'),datafeatures);
    dlmwrite(fullfile(fileparts(imDir),'web.datanames'),datanames);
    dlmwrite(fullfile(fileparts(imDir),'web.datalabels'),datalabels);
end

fprintf('\n\n');
