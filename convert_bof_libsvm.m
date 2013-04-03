%%                                                                                                         
%    Implementation of the bag-of-features (BoF) representation for images with                                 
%    Locality-constrained Linear Coding and Spatial Pyramid Matching.                                     
%                                                                                                         
%      Copyright (C) 2012  Drexel University.                                                             
%      Implemented by Dmitriy Bespalov (bespalov@gmail.com)                                               
%                                                                                                         
%    This file is part of image_bof_llc.                                                                  
%    image_bof_llc is free software: you can redistribute it and/or modify                                
%    it under the terms of the GNU General Public License as published by                                 
%    the Free Software Foundation, either version 3 of the License, or                                    
%    (at your option) any later version.                                                                  
%                                                                                                         
%    image_bof_llc is distributed in the hope that it will be useful,                                     
%    but WITHOUT ANY WARRANTY; without even the implied warranty of                                       
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                                        
%    GNU General Public License for more details.                                                         
%                                                                                                         
%    You should have received a copy of the GNU General Public License                                    
%    along with this program.  If not, see <http://www.gnu.org/licenses/>.                                
%
%%                                                                                                         





%% computes sparse high-dimensional representation for images using multiple BoF parameter models;         
%  final BoF vectors and corresponding category labels are saved in LibSVM format (text file).
%  
%  convert_bof_libsvm method calls get_image_descriptor and get_bof_llc methods
%
% INPUT ARGUMENTS:
%
%     model_filenames     -- array of strings, where each string specifies the location of
%                            a BoF parameters model
%
%     img_list_filename   -- list of images, stored in a text file
%                            (first column specifies each image file, 
%                             second column contains category label for that image)
%
%     save_to_filename    -- target location of text file to store final BoF vectors in LibSVM format
%                           
function convert_bof_libsvm(model_filenames, img_list_filename, save_to_filename)

models = {};

lid_outf = {};


%saves bof vectors for each type of descriptor into a separate file
%with "LID<type>" extension, where <type> = 'sift' | 'lbp' | 'rgbnorm'
for ii = 1:length(model_filenames)
    models{ii}=load(model_filenames{ii}, '-mat');
    one_lid_out_filename = sprintf('%s.LID%s', save_to_filename, models{ii}.model.lidType);
    fprintf('Opening %s file\n', one_lid_out_filename);
    lid_outf{ii} = fopen(one_lid_out_filename, 'w');
end


[images,categories] = readListOfImages(img_list_filename);
fprintf('Total number of images: %d, \n',length(images));

fid_f = fopen(save_to_filename, 'w');

for ii = 1:length(images)
    if exist(fullfile(images{ii}), 'file') > 0, 
        
        while true
            try
                im = imread(fullfile(images{ii})) ;  % in case imread
                                                     % fails to read
                                                     % image file on the
                                                     % first try 
                break;
            catch err
                fprintf(['####### Error occurred while reading %s file!\n Error ' ...
                         'message: %s\n\n'],   fullfile(images{ii}),         err.message);
                pause(5);
            end
        end
        
        final_hist = [];
        
        for jj = 1:length(model_filenames)
            
            [frames, descrs,new_width, new_height] = get_image_descriptor(models{jj}.model, im);

            % obtain bof (llc+spm) representation for extracted image descriptors
            [hist] = get_bof_llc(models{jj}.model, frames, descrs, new_width, new_height);

            % print bof vectors for each type of image descriptors into separate files
            fprintf(lid_outf{jj}, '%s', categories{ii});
            tnz = find(hist);
            for kk = 1:size(tnz, 2)
                fprintf(lid_outf{jj}, ' %d:%.6f', tnz(kk), hist(tnz(kk)));
            end
            fprintf(lid_outf{jj}, '\n');
            
            % concatenate bof vectors for each type of image descriptor
            final_hist = cat(2, final_hist, hist);
        end

        % normalize final BoF vector
        final_hist = final_hist./sqrt(sum(final_hist.^2));
        
        fprintf(fid_f, '%s', categories{ii});
        tnz = find(final_hist);
        
        for jj = 1:size(tnz, 2)
            fprintf(fid_f, ' %d:%.6f', tnz(jj), final_hist(tnz(jj)));
        end
        
        fprintf(fid_f, '\n');
    
    else
        fprintf('!!!ERROR Cant find file: %s\n\n', images{ii});
    end
end

fclose(fid_f);

for ii = 1:length(model_filenames)
    fclose(lid_outf{ii});
end


% reading list of images
function [images,categories] = readListOfImages(img_list_filename)
fid = fopen(img_list_filename);
tmp1 = textscan(fid, '%s %s\n');  % first column is location of the image file, 
                                  % second column is its category label
fclose(fid);
images = {};
categories = {};
for ci = 1:length(tmp1{1})
    images = {images{:}, tmp1{1}{ci}};
    categories = {categories{:}, tmp1{2}{ci}};
end
