const express = require("express");
const router = express.Router();
const userController = require("../controllers/userController");
const uploadfile = require("../middlewares/images");
const { forgotPassword, resetPassword , verifyCode } = require("../controllers/authController");
const { requireAuthUser } = require("../middlewares/authMiddlewares");
const { ControledAcces } = require("../middlewares/AccessControllers");

router.post("/create-admin", requireAuthUser, ControledAcces("admin"), uploadfile.single("image_User"), userController.createAdmin);
router.post("/create-enseignant", requireAuthUser, ControledAcces("admin"), uploadfile.single("image_User"), userController.createEnseignant);
router.post("/create-etudiant", requireAuthUser, ControledAcces("admin", "enseignant"), uploadfile.single("image_User"), userController.createEtudiant);

router.get("/getAllUsers", requireAuthUser, ControledAcces("admin", "etudiant"), userController.getAllUsers);
router.get("/admins", requireAuthUser, ControledAcces("admin"), userController.getAdmins);
router.get("/enseignants", requireAuthUser, ControledAcces("admin", "enseignant" ,  "etudiant"), userController.getEnseignants);
router.get("/etudiants", requireAuthUser, ControledAcces("admin", "enseignant" ,  "etudiant"), userController.getEtudiants);
router.get("/getUserById/:id", requireAuthUser, ControledAcces("admin", "enseignant", "etudiant"), userController.getUserById);

router.put("/update/:id", requireAuthUser, ControledAcces("admin", "enseignant", "etudiant"), uploadfile.single("image_User"), userController.updateUserById);
router.put("/update-password/:id", requireAuthUser, ControledAcces("admin", "enseignant", "etudiant"), userController.updatePassword);

router.delete("/deleteAllUsers", requireAuthUser, ControledAcces("admin"), userController.deleteAllUsers);
router.delete("/delete/:id", requireAuthUser, ControledAcces("admin"), userController.deleteUserById);

router.post("/login", userController.login);
router.post("/logout", requireAuthUser, userController.logout);
router.get("/me", requireAuthUser, userController.getUserAuth);

router.post("/forgot-password", forgotPassword);
router.post("/reset-password", resetPassword);
router.post("/verify-code", verifyCode);


module.exports = router;
