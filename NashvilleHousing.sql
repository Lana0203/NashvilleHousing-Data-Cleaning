-- Preview data

SELECT * FROM CleaningProject..NashvilleHousing;

------------------------------------------------------------------------------------------------------------------------------------

-- Standardize date format

ALTER TABLE NashvilleHousing
ALTER COLUMN SaleDate DATE;

------------------------------------------------------------------------------------------------------------------------------------

-- Populate missing PropertyAddress data

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM CleaningProject..NashvilleHousing a 
JOIN CleaningProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] != b.[UniqueID ]
WHERE a.PropertyAddress is null


UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM CleaningProject..NashvilleHousing a 
JOIN CleaningProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] != b.[UniqueID ]
WHERE a.PropertyAddress is null

------------------------------------------------------------------------------------------------------------------------------------

-- Breaking out property address into individual columns (address, city)

SELECT
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) AS City
FROM CleaningProject..NashvilleHousing;

ALTER TABLE NashvilleHousing
ADD PropertyAddressSplit varchar(255);

UPDATE CleaningProject..NashvilleHousing
SET PropertyAddressSplit = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1);

ALTER TABLE CleaningProject..NashvilleHousing
ADD PropertyCitySplit varchar(255);

UPDATE CleaningProject..NashvilleHousing
SET PropertyCitySplit = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress));

------------------------------------------------------------------------------------------------------------------------------------

-- Breaking out property address into individual columns (address, city, state)

SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM CleaningProject..NashvilleHousing;

ALTER TABLE CleaningProject..NashvilleHousing
ADD OwnerAddressSplit varchar(255);

UPDATE CleaningProject..NashvilleHousing
SET OwnerAddressSplit = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3);

ALTER TABLE CleaningProject..NashvilleHousing
ADD OwnerCitySplit varchar(255);

UPDATE CleaningProject..NashvilleHousing
SET OwnerCitySplit = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);

ALTER TABLE CleaningProject..NashvilleHousing
ADD OwnerStateSplit varchar(255);

UPDATE CleaningProject..NashvilleHousing
SET OwnerStateSplit = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

------------------------------------------------------------------------------------------------------------------------------------

-- Change the 'Y' and 'N' values to 'Yes' and 'No' in the SoldAsVacant field

SELECT DISTINCT(SoldAsVacant), count(SoldAsVacant) AS SoldAsVacant_Count
FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY SoldAsVacant_Count;


SELECT SoldAsVacant,
	CASE
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END 
		AS SoldAsVacant_Updated
FROM CleaningProject..NashvilleHousing;

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
						END;

------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates
WITH RowNumCTE AS(
SELECT*,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
					UniqueID
					) row_num
FROM CleaningProject..NashvilleHousing
--ORDER BY ParcelID
)
DELETE
FROM RowNumCTE
WHERE row_num > 1;

------------------------------------------------------------------------------------------------------------------------------------

-- Delete Unused Columns

ALTER TABLE CleaningProject..NashvilleHousing
DROP COLUMN SaleDate, OwnerAddress, TaxDistrict, PropertyAddress
