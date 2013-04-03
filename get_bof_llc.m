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
%
%    The source code in this file was partially derived from two freely-available online packages:
%
%    get_LLC_coefficients method was derived from:
%      Locality-constrained Linear Coding (LLC).                                        
%      Copyright (C) 2010  Jinjun Wang and Jianchao Yang (jyang29@illinois.edu).                          
%      URL: http://www.ifp.illinois.edu/~jyang29/codes/CVPR10-LLC.rar (accessed in Dec. 2012)             
%
%    CompilePyramid method was derived from:
%      Spatial Pyramid Matching.                                                        
%      Copyright (C) 2009  Joe Tighe (jtighe@cs.unc.edu) and Svetlana Lazebnik (lazebnik@cs.unc.edu).     
%      URL: http://www.cs.illinois.edu/homes/slazebni/research/SpatialPyramid.zip (accessed in Dec. 2012) 
%
%%                                                                                                         



%% encodes each image descriptor in descrs with model.knn codewords,                                       
%  then computes spatial pyramid from the coded descriptors using max-pooling
%
% INPUT ARGUMENTS:
%
%     model               -- Matlab object with BoF parameters 
%                            (model.vocab and model.kdtree must be set
%                            using get_kdvocab method)
% 
%     frames              -- matrix that stores meta-info for extracted descriptors;
%                            each column contains: descriptor's x/y-position, scale, and orientation
%
%     descrs              -- matrix that stores feature vectors for extracted descriptors 
%                            (each column is a feature vector)
%
%     new_width,          -- dimensions of the input image after rescaling
%     new_height             
%
% RETURNS:
%
%     hist               -- final BoF vector (all levels of the spatial
%                           pyramid are concatenated to form a single vector)
%     
%     llc_coeffs         -- matrix of size NxM that contains codings of individual image descriptors;
%                           each row is a sparse vector with model.knn non-zero coefficients, where
%                           N is size of codebook (i.e., # of columns in model.vocab) and 
%                           M is number of columns in frames and descrs
%                           
function [hist, llc_coeffs] = get_bof_llc(model, frames, descrs, width, height)

    binsa = double(vl_kdtreequery(model.kdtree, single(model.vocab), ...
                                  single(descrs), 'MaxComparisons', 500, 'NUMNEIGHBORS', model.knn));
    
    llc_coeffs = get_LLC_coefficients(double(model.vocab)', double(descrs)', binsa', model.beta, model.sigma);
    llc_coeffs = llc_coeffs';

    hist = CompilePyramid( model, frames, llc_coeffs, width, height);

    
% Locality-constrained Linear Coding (LLC)
function [llc_coeffs] = get_LLC_coefficients(vocab_t, descrs, nns, beta, sigma)
    
    knn = size(nns, 2);
    nframe = size(nns, 1);
    nbase = size(vocab_t, 1);
    
    II = eye(knn, knn);

    llc_coeffs = zeros(nframe, nbase);
    
    eps_thresh = 0.0001;
    
    for i=1:nframe
        idx = nns(i,:);
        z = vocab_t(idx,:) - repmat(descrs(i,:), knn, 1);% shift ith pt to origin
        C = z*z';                                        % local covariance

        dd = sqrt(diag(C));
        dd = exp(dd ./ sigma);
        
        C = C + II*eps_thresh*trace(C);                        %   regularlization (K>D)
        
        C = C + beta*diag(dd);
        
        w = C\ones(knn,1);
        
        w = w/sum(w);                                    % enforce sum(w)=1
        
        llc_coeffs(i,idx) = w';
   
    end
    
    
% construction of Spatial Pyramid Matching (SPM)
function [ pyramid ] = CompilePyramid(model,  frames, llc_coeffs, width, height )

pyramidLevels = model.pyramidLevels;

if isfield(model, 'oneLevelSPM') && model.oneLevelSPM > 0
    binsHigh = model.oneLevelSPM;
    pyramidLevels = 1;
else
    binsHigh = 2^(model.pyramidLevels-1);
end

% pooling of coded descriptors to obtain a sparse high-dimensional vector
% (akin to a histogram) for every level in SPM
pyramid_cell = cell(pyramidLevels,1);
pyramid_cell{1} = zeros(binsHigh, binsHigh, model.numWords);

for l = 1:pyramidLevels
    for i=1:binsHigh
        for j=1:binsHigh
            
            % find the coordinates of the current bin
            x_lo = floor(width/binsHigh * (i-1));
            x_hi = floor(width/binsHigh * i);
            y_lo = floor(height/binsHigh * (j-1));
            y_hi = floor(height/binsHigh * j);
            
            bin_frames = find(frames(1,:) > x_lo & frames(1,:) <= x_hi & ...
                              frames(2,:) > y_lo & frames(2,:) <= y_hi);
            
            % max-pooling is used
            tmp_hist = max(llc_coeffs(:, bin_frames), [], 2);

            if (length(tmp_hist) > 0),
                pyramid_cell{l}(i,j,:) = tmp_hist;
            end
        end
    end
    binsHigh = binsHigh/2;
end

% concatenate histograms for each SPM level 
pyramid = [];
for l = 1:pyramidLevels
    pyramid = [pyramid pyramid_cell{l}(:)' ];
end

pyramid = pyramid./sqrt(sum(pyramid.^2));



