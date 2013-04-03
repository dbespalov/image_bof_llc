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


%% computes a codebook for randomly-sampled descriptors from a list of images                              
%
% INPUT ARGUMENTS:
%
%     model_filename      -- location of the input file (model) with BoF parameters
% 
%     img_list_filename   -- list of images, stored in a text file
%                            (first column specifies each image file, 
%                             second column contains category label for that image)
%
%     save_to_filename    -- target location of the BoF model with the new codebook added as a parameter;
%                            all parameters from model_filename are saved in the new model;
%                            codewords are saved as columns of matrix model.vocab, and
%                            model.kdtree stores approximate kd-tree datastructure
%
%
% NOTE: hierarchical integer k-means (clustering) is used for efficient codebook construction
%
function get_kdvocab(model_filename, img_list_filename, save_to_filename)

tmp_model=load(model_filename, '-mat');
model = tmp_model.model;

randn('state',model.randSeed) ;
rand('state',model.randSeed) ;
vl_twister('state',model.randSeed) ;

[images,categories] = readListOfImages(img_list_filename);
fprintf('Total number of images: %d, \n',length(images));

% getting random descriptors from each image
kd_descrs = [];
for ii = 1:length(images)
    if exist(fullfile(images{ii}), 'file') > 0, 
        
        while true
            try
                im = imread(fullfile(images{ii})) ;
                break;
            catch err
                fprintf(['####### Error occurred while reading %s file!\n Error ' ...
                         'message: %s\n\n'],   fullfile(images{ii}),         err.message);
                pause(1);
            end
        end
        
        [one_img_frames, one_img_descrs] = get_image_descriptor(model, im);
        
        kd_descrs = cat(2, kd_descrs, vl_colsubset(one_img_descrs, model.descrsPerImg));
    else
        fprintf('!!!ERROR Cant find file: %s\n\n', images{ii});
    end
end

kd_descrs = vl_colsubset(kd_descrs, model.descrsTotal);
    
fprintf(['Doing hikmeans for size(kd_descrs)=%dx%d, ' ...
         'model.numWords=%d, descrsPerImage=%d, descrsTotal=%d\n'], size(kd_descrs), model.numWords,model.descrsPerImg,model.descrsTotal);

% hierarchical k-means clustering
tree = vl_hikmeans(uint8(kd_descrs), 4, model.numWords, 'verbose', 'method', 'elkan', 'MaxIters', 1000);

model.vocab = single(getLeafs(tree, []));
model.numWords = size(model.vocab, 2);
model.kdtree = vl_kdtreebuild(model.vocab);

fprintf('Done with hikmeans! model.numWords=%d\n', model.numWords);

save(save_to_filename, 'model', '-mat', '-v7.3');



% get leaf clusters from the hierarchical k-means tree
function [leafs] = getLeafs(tree, leafs)
if length(tree.sub) == 0 
    leafs = cat(2, leafs, tree.centers);
else
    for ii = 1:length(tree.sub)
        leafs = getLeafs(tree.sub(ii), leafs);
    end
end

% reading list of images
function [images,categories] = readListOfImages(img_list_filename)
fid = fopen(img_list_filename);
tmp1 = textscan(fid, '%s %s\n');  % first column is filepath, second
                                  % column is the image label
fclose(fid);
images = {};
categories = {};
for ci = 1:length(tmp1{1})
    images = {images{:}, tmp1{1}{ci}};
    categories = {categories{:}, tmp1{2}{ci}};
end

