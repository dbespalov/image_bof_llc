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




%% computes image descriptors for an image                                                                  
%
% INPUT ARGUMENTS:
%
%     model               -- BoF parameter model
%
%     im                  -- input image
%         
% RETURNS:
%
%     frames              -- matrix that stores meta-info for extracted descriptors;
%                            each column contains: descriptor's x/y-position, scale, and orientation
%
%     descrs              -- matrix that stores feature vectors for extracted descriptors
%
%     new_width,          -- dimensions of the rescaled image im, so that its largest
%     new_height             side does not exceed model.maxImgSize
%
function [frames, descrs, new_width, new_height] = get_image_descriptor(model, im)

% resize image
im = resizeImage(model, im);

new_width=size(im, 2);
new_height=size(im, 1);

% extract phow descriptors from im
if (strcmp(model.lidType, 'SIFT') || strcmp(model.lidType, 'sift'))
    im = getGrayImg(im);
    [frames, descrs] = vl_phow(im, model.phowOpts{:});

% extract normalized rgb histograms from im
elseif (strcmp(model.lidType, 'RGBNORM') || strcmp(model.lidType, 'rgbnorm'))
    
    [frames, descrs] = get_rgb_descriptor(model, im);

% extract local binary pattern descriptors from im
elseif (strcmp(model.lidType, 'LBP') || strcmp(model.lidType, 'lbp'))
    
    descrs = {};
    frames = {};
    im = getGrayImg(im);
    
    for ss = 1:length(model.phowSizes)
        tmp_lbps = vl_lbp(im, model.phowSizes(ss));
        
        tmp_lbps = tmp_lbps * 512.0;
        tmp_lbps(find(tmp_lbps>255.0))=255.0;
        
        frame_len = size(tmp_lbps, 1)*size(tmp_lbps, 2);
        ss_frames = zeros(4, frame_len);
        ss_descrs = zeros(size(tmp_lbps,3), frame_len, 'uint8');
        frame_id = 1;
        for ii = 1:size(tmp_lbps, 1)
            for jj = 1:size(tmp_lbps, 2)
                
                ss_frames(1, frame_id) = (jj-1)*model.phowSizes(ss) + 1 + (model.phowSizes(ss)/2);
                ss_frames(2, frame_id) = (ii-1)*model.phowSizes(ss) + 1 + (model.phowSizes(ss)/2);
                
                ss_descrs(:, frame_id) = uint8(tmp_lbps(ii, jj, :));
                
                frame_id = frame_id + 1;
            end
        end
        
        if ss == 1 
            descrs = ss_descrs;
            frames = ss_frames;
        else        
            descrs = cat(2, descrs, ss_descrs);
            frames = cat(2, frames, ss_frames);
        end 
    end


else 
    fprintf('!!!ERROR: Unknown LID type: %s\n', model.lidType);
end


function im = resizeImage(model, im)
if size(im,1) > size(im,2)
    if size(im,1) > model.maxImgSize, 
        im = imresize(im, [model.maxImgSize NaN]) ; 
    end
else
    if size(im,2) > model.maxImgSize, 
        im = imresize(im, [NaN model.maxImgSize]) ; 
    end
end


function im = getGrayImg(im)
if size(im,3) > 1, im = rgb2gray(im); end
im = im2single(im) ;



% implementation of the normalized RGB histogram descriptor
function [frames, descrs] = get_rgb_descriptor(model, im)

bins_per_channel = 26;

if size(im, 3) ~= 3
    %fprintf(' #####      WARNING:    need 3 channels in image! found: %d\n', size(im,3));
    new_im = zeros([size(im, 1) size(im, 2) 3]);
    
    new_im(:,:,1) = im(:,:,1);
    new_im(:,:,2) = im(:,:,1);
    new_im(:,:,3) = im(:,:,1);
    
    im = new_im;
end

height= size(im,1);
width= size(im,2);

descrs = [];
frames = [];

for ss = 1:length(model.phowSizes)
    
    window_size = model.phowSizes(ss);
    
    histimg_sizeY = floor(height / window_size);
    histimg_sizeX = floor(width / window_size);
    
    ss_frames = zeros(4, histimg_sizeX*histimg_sizeY);
    ss_descrs = zeros(bins_per_channel*3, histimg_sizeX*histimg_sizeY);
    
    norm_eps_thresh = 0.0001;
    ins_idx = 1;
    
    for ii = 1 : window_size : height
        for jj = 1 : window_size : width
            
            x_lo = jj;
            x_hi = jj+window_size-1;
            y_lo = ii;
            y_hi = ii+window_size-1;
            
            if x_hi < width && y_hi < height 
                
                intensity_hist = get_imcolor_hist(im(y_lo:y_hi, x_lo:x_hi, :), bins_per_channel);
                
                if length(find(intensity_hist>0)) > 0 
                    ss_descrs(:, ins_idx) = intensity_hist(:)';
                    ss_frames(1, ins_idx) = (x_lo+x_hi)/2;
                    ss_frames(2, ins_idx) = (y_lo+y_hi)/2;
                    ins_idx=ins_idx+1;
                end
            end
        end
    end
    
    if ins_idx > 1
        if ss == 1 
            descrs = ss_descrs(:, 1:ins_idx-1);
            frames = ss_frames(:, 1:ins_idx-1);
        else
            descrs = cat(2, descrs, ss_descrs(:, 1:ins_idx-1));
            frames = cat(2, frames, ss_frames(:, 1:ins_idx-1));
        end
    end
end


function [intensity_hist] = get_imcolor_hist(im_region, bins_per_channel)

    im_r = normalizeChannel(im_region(:,:,1));
    im_g = normalizeChannel(im_region(:,:,2));
    im_b = normalizeChannel(im_region(:,:,3));
    
    stepv=(2.9+2.9)/(bins_per_channel-3);
    edges = [-inf -2.9:stepv:2.9 inf];

    bins_r = histc(im_r, edges);
    bins_g = histc(im_g, edges);
    bins_b = histc(im_b, edges);
    
    intensity_hist = cat(1, bins_r(:), bins_g(:), bins_b(:));
    intensity_hist = intensity_hist./sqrt(sum(intensity_hist(:).^2));
    
    intensity_hist = intensity_hist * 512.0;
    intensity_hist(find(intensity_hist>255.0))=255.0;
    
    intensity_hist = uint8(intensity_hist);
    
function [norm_chan] = normalizeChannel(im_chan)
    vec_chan = double(im_chan(:));
    norm_chan = (vec_chan - mean(vec_chan)) ./ std(vec_chan);
