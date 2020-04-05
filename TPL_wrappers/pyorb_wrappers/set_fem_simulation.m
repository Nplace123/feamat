function [mesh, fespace] = set_fem_simulation( fem_specifics, varargin )
% Assemble the mesh and the FE space, given some input specifics
% input=
%           fem_specifics: struct containing the information to build the
%           mesh and the fespace; in particular it is necessary to know 
%           the number of DOFs per direction, the degree of the
%           polynomials, the type of model to be constructed and whether
%           non-homogrnrous Dirichlet BCs have to be used or not
% output=
%           mesh: mesh for the FE problem to be solved 
%           fespace: fespace for the FE problem to be solved 
 
n_elements_x = fem_specifics.number_of_elements;
poly_degree  = fem_specifics.polynomial_degree;

n_elements_y = n_elements_x;

% geometry  definition
bottom_left_corner_x = 0;
bottom_left_corner_y = 0;

L = 1.0;
H = 1.0;

mesh = create_mesh(bottom_left_corner_x, ...
               bottom_left_corner_y, ...
               L,H,n_elements_x,n_elements_y);

current_model = fem_specifics.model;

if nargin == 1
    bc_flags = [0 0 1 0];
else
    bc_flags = varargin{1};
end

if strcmp( current_model, 'nonaffine' )
    bc_flags = [1 1 1 1];
end

current_dirichlet = fem_specifics.use_nonhomogeneous_dirichlet;
if strcmp( current_model, 'nonaffine' ) && strcmp( current_dirichlet, 'Y' )
    bc_flags = [1 1 0 1];
end

fespace = create_fespace( mesh, poly_degree, bc_flags );

end