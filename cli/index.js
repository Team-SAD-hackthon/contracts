const fs = require("fs");
const hre = require("hardhat");
const inquirer = require("inquirer");
let userParams;

async function readFileData(path, fileName) {
  // getting the data from the file
  const dataToWrite = await fs.promises.readFile(path, (error, data) => {
    if (error) {
      console.log("Error", error);
      return null;
    }
    return data;
  });

  // Creating a new file and writing the data to it.
  const writeStream = fs.createWriteStream(`${fileName}.sol`);
  writeStream.write(dataToWrite);
  writeStream.end();
}

async function deployContract(contractName, arg) {
  const Master = await hre.ethers.getContractFactory(`${contractName}`);
  const mock = await Master.deploy(arg);

  await mock.deployed();
}

inquirer
  .prompt([
    {
      type: "checkbox",
      name: "chains",
      message: "Chains you want to deploy on",
      choices: ["Polygon", "Arbitrum", "Optimism"],
    },
    {
      type: "list",
      name: "scalability",
      message: "Level of throughput and gas fees",
      choices: ["High", "Medium", "Low"],
    },
    {
      type: "list",
      name: "security",
      message: "Level of security",
      choices: ["High", "Medium", "Low"],
    },
    {
      name: "protocol",
      message: "Enter the absolute path of your smart contract file",
    },
    {
      name: "protocolName",
      message: "Enter the protocol name",
    },
    {
      name: "arg",
      message: "Enter argument",
    },
  ])
  .then(async (answers) => {
    userParams = answers;
    console.log("log", answers);
    // Make smart contract file
    await readFileData(answers.protocol, answers.protocolName);
    // // Deploy the contract
    deployContract(answers.protocolName, answers.arg);
  })
  .catch((error) => {
    if (error.isTtyError) {
      // Prompt couldn't be rendered in the current environment
    } else {
      // Something else went wrong
    }
  });
