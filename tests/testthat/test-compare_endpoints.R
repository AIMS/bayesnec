require(bayesnec)

ecx4param <- pull_out(manec_gausian_identity, model = "ecx4param")
nec4param <- nec_gausian_identity
ce <- compare_endpoints(list(ecx4param = ecx4param, nec4param = nec4param))

test_that("x must be a named list", {
  expect_error(compare_endpoints(list(ecx4param, nec4param)))
  expect_error(compare_endpoints(ecx4param, nec4param))
})

test_that("output is a list of appropriately name elements", {
  expect_equal(class(ce), "list")
  expect_equal(length(ce), 5)  
})