
    Hierarchical integer k-means (clustering) is used for efficient vocabulary construction. 

    Three types of image descriptors are used: 
        1. PHOW (dense SIFT, extracted at multiple scales)
        2. Local binary pattern (texture descriptor)
        3. Normalized RGB Histograms (each histogram is scaled to mean=0 and std-dev=1)



image_bof_llc implements bag-of-features representation for images
that transforms image descriptors (i.e., dense feature vectors) into
a sparse high-dimensional vector. 

Three types of image descriptors are used: 
  1. PHOW  -- uniformly-sampled SIFT descriptors, extracted at multiple scales
  2. Local binary pattern (LBP)  
  3. Normalized RGB Histograms (RGBh) -- histogram for each color channel is normalized to mean=0 and std-dev=1



of intensities for each color channel is normalized to mean=0 and std-dev=1, then three histograms are concatenated to form a descriptor vector 



Implementation of the bag-of-features (BoF) representation for images
that transforms image descriptors (i.e., dense feature vectors) into
a sparse high-dimensional vector. 

BoF is sometimes referred to
as the bag of visual words model, which can be seen encoding
each image descriptor with a few visual words from a vocabulary.
Size of the vocabulary determines dimensionality of the 
resulting sparse vector. One of the popular approaches to building 
such vocabulary is to cluster a random sample of 
image descriptors and then retain centroids of the clusters as visual words.



This 

Implementation of Spatial Pyramid Matching (SPM) [1] that is available online [2].
Copyright (C) 2009 Joe Tighe (jtighe@cs.unc.edu) and Svetlana Lazebnik (lazebnik@cs.unc.edu).


Implementation of Locality-constrained Linear Coding (LLC) [3] that is available online [4].
Copyright (C) 2010  Jinjun Wang and Jianchao Yang (jyang29@illinois.edu).


[1] Svetlana Lazebnik, Cordelia Schmid, and Jean Ponce.
    Beyond Bags of Features: Spatial Pyramid Matching for Recognizing Natural Scene Categories.
    CVPR 2006.

[2] http://www.cs.illinois.edu/homes/slazebni/research/SpatialPyramid.zip (accessed in Dec 2012)

[3] Jinjun Wang, Jianchao Yang, Kai Yu, Fengjun Lv, Thomas Huang and Yihong Gong.
    Locality-constrained Linear Coding for Image Classification.
    CVPR 2010.

[4] http://www.ifp.illinois.edu/~jyang29/codes/CVPR10-LLC.rar (accessed in December 2012)










Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:
1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the
   distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
