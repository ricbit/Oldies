module Rakell where

import Data.List

-- Basic Math

type Scalar = Double
type Vector = (Scalar, Scalar, Scalar)

compareScalarEpsilon eps a b = abs (a - b) < eps

compareVectorEpsilon eps (a, b, c) (x, y, z) =
  and [comp a x, comp b y, comp c z] where
    comp = compareScalarEpsilon eps

addVector (a, b, c) (x, y, z) = (a+x, b+y, c+z)

subVector (a, b, c) (x, y, z) = (a-x, b-y, c-z)

dotVector (a, b, c) (x, y, z) = a*x + b*y + c*z

crossVector (a, b, c) (x, y, z) = (b*z - y*c, c*x - a*z, a*y - x*b)

scaleVector k (a, b, c) = (k * a, k * b, k * c)

modulus a = sqrt $ dotVector a a

normalize v
  | norm == 0 = (0, 0, 0)
  | otherwise = scaleVector (1 / norm) v
  where
    norm = modulus v

-- Rays and Intersections

type Origin = Vector
type Normal = Vector
type Plane = (Origin, Normal)

type Direction = Vector
type Ray = (Origin, Direction)

precision = 1e-5

intersectPlane plane@(planeOrigin, normal) ray@(rayOrigin, dir) 
  | compareScalarEpsilon precision 0 den = []
  | otherwise = [(dotVector normal (subVector planeOrigin rayOrigin)) / den]
  where
    den = dotVector dir normal

normalPlane plane@(origin, normal) pos = normal

-- Scene manipulation

type Object = (Ray -> [Scalar], Ray -> Vector)
type Scene = [Object]

intersectObject object@(intersect, normal) ray =
  zip (filter (> 1) $ intersect ray) (repeat object)

intersectScene scene ray
  | hits == [] = Nothing
  | otherwise = Just (minimumBy compareHits hits) where
      compareHits x y = compare (fst x) (fst y)
      hits = concat $ map (`intersectObject` ray) scene

createPlane plane scene = (intersectPlane plane, normalPlane plane) : scene

