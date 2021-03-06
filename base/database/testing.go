package database

import (
	"app/base"
	"app/base/models"
	"app/base/utils"
	"github.com/stretchr/testify/assert"
	"testing"
	"time"
)

func DebugWithCachesCheck(part string, fun func()) {
	fun()
	validAfter, err := CheckCachesValidRet()
	if err != nil {
		utils.Log("error", err).Panic("Could not check validity of caches")
	}

	if !validAfter {
		utils.Log("part", part).Panic("Cache mismatch created")
	}
}

type key struct {
	AccountID  int
	AdvisoryID int
}

type advisoryCount struct {
	RhAccountID int
	AdvisoryID  int
	Count       int
}

// nolint: lll
func CheckCachesValidRet() (bool, error) {
	valid := true
	var aad []models.AdvisoryAccountData

	tx := Db.BeginTx(base.Context, nil)
	err := tx.Set("gorm:query_option", "FOR SHARE OF advisory_account_data").
		Order("rh_account_id, advisory_id").Find(&aad).Error
	if err != nil {
		return false, err
	}
	var counts []advisoryCount

	err = tx.Select("sp.rh_account_id, sa.advisory_id, count(*)").
		Table("system_advisories sa").
		Joins("JOIN system_platform sp ON sa.rh_account_id = sp.rh_account_id AND sa.system_id = sp.id").
		Where("sa.when_patched IS NULL AND sp.stale = false AND sp.last_evaluation IS NOT NULL").
		Order("sp.rh_account_id, sa.advisory_id").
		Group("sp.rh_account_id, sa.advisory_id").
		Find(&counts).Error
	if err != nil {
		return false, err
	}

	cached := map[key]int{}
	calculated := map[key]int{}

	for _, val := range aad {
		cached[key{val.RhAccountID, val.AdvisoryID}] = val.SystemsAffected
	}
	for _, val := range counts {
		calculated[key{val.RhAccountID, val.AdvisoryID}] = val.Count
	}

	for key, cachedCount := range cached {
		calcCount := calculated[key]

		if cachedCount != calcCount {
			utils.Log("advisory_id", key.AdvisoryID, "account_id", key.AccountID,
				"cached", cachedCount, "calculated", calcCount).Error("Cached counts mismatch")
			valid = false
		}
	}

	for key, calcCount := range calculated {
		cachedCount := calculated[key]

		if cachedCount != calcCount {
			utils.Log("advisory_id", key.AdvisoryID, "account_id", key.AccountID,
				"cached", cachedCount, "calculated", calcCount).Error("Cached counts mismatch")
			valid = false
		}
	}
	tx.Commit()
	tx.RollbackUnlessCommitted()
	return valid, nil
}

func CheckCachesValid(t *testing.T) {
	valid, err := CheckCachesValidRet()
	assert.Nil(t, err)
	assert.True(t, valid)
}

func CheckAdvisoriesInDB(t *testing.T, advisories []string) []int {
	var advisoriesObjs []models.AdvisoryMetadata
	err := Db.Where("name IN (?)", advisories).Find(&advisoriesObjs).Error
	assert.Nil(t, err)
	assert.Equal(t, len(advisoriesObjs), len(advisories))
	var ids []int //nolint:prealloc
	for _, advisoryObj := range advisoriesObjs {
		ids = append(ids, advisoryObj.ID)
	}
	return ids
}

func CheckPackagesNamesInDB(t *testing.T) {
	var names []models.PackageName
	assert.NoError(t, Db.Order("name").Find(&names).Error)
	assert.Len(t, names, 10)
	assert.Equal(t, names[0].Name, "bash")
	assert.Equal(t, names[1].Name, "curl")
}

func CheckSystemJustEvaluated(t *testing.T, inventoryID string, nAll, nEnh, nBug, nSec, nInstall, nUpdate int,
	thirdParty bool) {
	var system models.SystemPlatform
	assert.Nil(t, Db.Where("inventory_id = ?::uuid", inventoryID).First(&system).Error)
	assert.NotNil(t, system.LastEvaluation)
	assert.True(t, system.LastEvaluation.After(time.Now().Add(-time.Second)))
	assert.Equal(t, nAll, system.AdvisoryCountCache)
	assert.Equal(t, nEnh, system.AdvisoryEnhCountCache)
	assert.Equal(t, nBug, system.AdvisoryBugCountCache)
	assert.Equal(t, nSec, system.AdvisorySecCountCache)
	assert.Equal(t, nInstall, system.PackagesInstalled)
	assert.Equal(t, nUpdate, system.PackagesUpdatable)
	assert.Equal(t, thirdParty, system.ThirdParty)
}

func CheckAdvisoriesAccountData(t *testing.T, rhAccountID int, advisoryIDs []int, systemsAffected int) {
	var advisoryAccountData []models.AdvisoryAccountData
	err := Db.Where("rh_account_id = ? AND advisory_id IN (?)", rhAccountID, advisoryIDs).
		Find(&advisoryAccountData).Error
	assert.Nil(t, err)

	sum := 0
	for _, item := range advisoryAccountData {
		sum += item.SystemsAffected
	}
	// covers both cases, when we have advisory_account_data stored with 0 systems_affected, and when we delete it
	assert.Equal(t, systemsAffected*len(advisoryIDs), sum, "sum of systems_affected does not match")
}
