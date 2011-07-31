import Rakell
import Test.QuickCheck

compareVector = compareVectorEpsilon 1e-3
compareScalar = compareScalarEpsilon 1e-3

prop_CompareEquals :: Vector -> Bool
prop_CompareEquals a = compareVector a a

prop_CompareDifferent :: Vector -> Bool
prop_CompareDifferent a = not $ compareVector a (addVector a (1e-2, 0 ,0))

prop_CompareSimilar :: Vector -> Bool
prop_CompareSimilar a = compareVector a (addVector a (1e-4, 0 ,0))

prop_AddSymmetry :: Vector -> Vector -> Bool
prop_AddSymmetry a b = compareVector (addVector a b) (addVector b a)

prop_SubSymmetry :: Vector -> Vector -> Bool
prop_SubSymmetry a b =
  compareVector (subVector a b) $ scaleVector (-1) (subVector b a)

prop_AddAssociative :: Vector -> Vector -> Vector -> Bool
prop_AddAssociative a b c = compareVector x y where
  x = addVector a (addVector b c)
  y = addVector (addVector a b) c

prop_AddNeutral :: Vector -> Bool
prop_AddNeutral a = compareVector (addVector a zero) a where
  zero = (0, 0, 0)

prop_SubNeutral :: Vector -> Bool
prop_SubNeutral a = compareVector (subVector a zero) a where
  zero = (0, 0, 0)

prop_SubEquals :: Vector -> Bool
prop_SubEquals a = compareVector (subVector a a) zero where
  zero = (0, 0, 0)

prop_DotSymmetry :: Vector -> Vector -> Bool
prop_DotSymmetry a b = compareScalar (dotVector a b) (dotVector b a)

prop_DotNeutral :: Vector -> Bool
prop_DotNeutral a = compareScalar 0 (dotVector a (0, 0, 0))

prop_DotDistributive :: Vector -> Vector -> Vector -> Bool
prop_DotDistributive a b c =
  compareScalar v1 v2 where
    v1 = dotVector a (addVector b c)
    v2 = (dotVector a b) + (dotVector a c)

prop_DotPerpendicular :: Scalar -> Scalar -> Bool
prop_DotPerpendicular a b = compareScalar (dotVector (a, b, 0) (-b, a, 0)) 0

prop_ModulusXOnly :: Scalar -> Bool
prop_ModulusXOnly a = compareScalar (modulus (a, 0, 0)) (abs a)

prop_ModulusDiagonal :: Scalar -> Bool
prop_ModulusDiagonal a = compareScalar (modulus (a, a, a)) (abs a * sqrt 3)

prop_Normalize :: Vector -> Property
prop_Normalize a = modulus a /= 0 ==> compareScalar 1 $ modulus $ normalize a

prop_ScaleUnit :: Vector -> Bool
prop_ScaleUnit a = compareVector a (scaleVector 1 a)

prop_ScaleArbitrary :: Scalar -> Vector -> Bool
prop_ScaleArbitrary k a =
  compareScalar (abs $ k * modulus a) (modulus $ scaleVector k a)

prop_CrossNormal :: Vector -> Vector -> Property
prop_CrossNormal a b = a /= b ==> and [perp a c, perp b c] where
  perp x y = compareScalar 0 $ dotVector x y
  c = crossVector a b

prop_CrossSymmetry :: Vector -> Vector -> Bool
prop_CrossSymmetry a b =
  compareVector (crossVector a b) $ scaleVector (-1) $ crossVector b a

prop_CrossScalar :: Scalar -> Vector -> Vector -> Bool
prop_CrossScalar k a b = compareVector x y where
  x = crossVector a $ scaleVector k b
  y = scaleVector k $ crossVector a b

prop_PlaneIntersectionParallel :: Plane -> Vector -> Vector -> Property
prop_PlaneIntersectionParallel plane@(planeOrigin, normal) origin dir =
  not (compareScalar 0 (dotVector dir normal)) ==>
    intersectPlane plane ray == [] where
      ray = (origin, crossVector normal dir)

prop_PlaneIntersectionBelow :: Plane -> Property
prop_PlaneIntersectionBelow plane@(origin, normal) =
  normal /= (0,0,0) ==> head inter > 0 where
    inter = intersectPlane plane ray 
    ray = (subVector origin normal, normal)

prop_PlaneIntersectionAbove :: Plane -> Property
prop_PlaneIntersectionAbove plane@(origin, normal) =
  normal /= (0,0,0) ==> head inter < 0 where
    inter = intersectPlane plane ray
    ray = (addVector origin normal, normal)

prop_PlaneNormal :: Plane -> Vector -> Bool
prop_PlaneNormal plane@(origin, normal) pos =
  compareVector normal $ normalPlane plane pos

createObject hits = (\x -> hits, \x -> (0, 0, 0))

prop_IntersectObjectSameLength :: [Scalar] -> Ray -> Bool
prop_IntersectObjectSameLength hits ray =
  length (intersectObject (createObject hits) ray) <= length hits

prop_IntersectObjectGreaterThanOne :: [Scalar] -> Ray -> Bool
prop_IntersectObjectGreaterThanOne hits ray =
  all (\x -> fst x > 1) (intersectObject (createObject hits) ray)

--prop_IntersectSceneSmaller :: [[Scalar]] -> Ray -> Property
--prop_IntersectSceneSmaller hitList ray = allHits /= [] ==>
--  (minimum allHits) == (fst $ maybe dummy id (intersectScene scene ray))
--    where
--      scene = [createObject hit | hit <- hitList]
--      allHits = concat hitList
--      dummy = (0, createObject [])

tests = do
  quickCheck prop_AddSymmetry
  quickCheck prop_AddAssociative
  quickCheck prop_AddNeutral
  quickCheck prop_CompareEquals
  quickCheck prop_CompareDifferent
  quickCheck prop_CompareSimilar
  quickCheck prop_DotSymmetry
  quickCheck prop_DotNeutral
  quickCheck prop_DotPerpendicular
  quickCheck prop_DotDistributive
  quickCheck prop_ModulusXOnly
  quickCheck prop_ModulusDiagonal
  quickCheck prop_Normalize
  quickCheck prop_ScaleUnit
  quickCheck prop_ScaleArbitrary
  quickCheck prop_CrossNormal
  quickCheck prop_CrossSymmetry
  quickCheck prop_CrossScalar
  quickCheck prop_SubSymmetry
  quickCheck prop_SubEquals
  quickCheck prop_SubNeutral
  quickCheck prop_PlaneIntersectionParallel
  quickCheck prop_PlaneIntersectionBelow
  quickCheck prop_PlaneIntersectionAbove
  quickCheck prop_PlaneNormal
  quickCheck prop_IntersectObjectSameLength
  quickCheck prop_IntersectObjectGreaterThanOne
--  quickCheck prop_IntersectSceneSmaller

main = tests 
