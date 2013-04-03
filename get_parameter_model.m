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




%% creates a model with parameters for BoF and (optionally) saves the model into a file                    
%
% INPUT ARGUMENTS:
%
%     save_to_filename    -- target filename for the model
%                            (model is not saved when save_to_filename='skip')
%   
%     numWords            -- size of the codebook (i.e., vocabulary of visual words)
%
%     pyramidLevels       -- number of levels in the spatial pyramid
%
%     lidType             -- type of image descriptor
%                            accepted strings are:
%                                'sift'     : PHOW descriptors
%                                'lbp'      : Local binary pattern
%                                'rgbnorm'  : Normalized RGB histograms
%         
% RETURNS:
%
%     model               -- BoF parameters model
%
%
% NOTE: additional parameters are hard-coded inside get_parameter_model function
%
function [model] = get_parameter_model(save_to_filename, numWords, pyramidLevels, lidType)

model.numWords = numWords;

model.maxImgSize = 300; % pix
model.phowSizes = [8, 16, 24]; %@ 300pix 
%model.phowSizes = [16, 32, 48]; %@ 600pix 
% Kai's cvpr 2011 for HoG: [18, 28, 38] @ 600pix

model.phowStep = 6;
% model.phowStep = 12; % @ 600pix

% supported image descriptors: 
% 'sift', 'rgbnorm' (normalized rbg histogram), 'lbp' (local binary pattern)
model.lidType = lidType;

% options for PHOW extraction by VLFeat library
% PHOW features are a variant of dense SIFT descriptors, 
% extracted at multiple scales.
model.phowOpts = {'Step', model.phowStep, 'Sizes', model.phowSizes};

% number of levels in SPM 
model.pyramidLevels=pyramidLevels;

% can be used to compute BoF for images at a single 
% partition level: e.g., 4x4
% model.oneLevelSPM=4;

% LLC parameters
model.knn=20; % number of codewords per descriptor 
model.beta=500;  
model.sigma=100; 

% parameters used for codebook construction with hierarchical k-means clustering
model.descrsPerImg = 500; % number of randomly-sampled descriptors from each image
model.descrsTotal  = 30000000; % total number of descriptors used for clustering

model.randSeed=67382; 

model

if (strcmp(save_to_filename, 'skip')==0)
    save(save_to_filename, 'model', '-mat', '-v7.3');
end



