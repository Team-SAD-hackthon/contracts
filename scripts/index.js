const fs = require("fs");
const hre = require("hardhat");
const inquirer = require("inquirer");
const ethers = require("ethers");

function getJsonRpcUrl(chain) {
  let jsonRpcUrl;
  switch (chain) {
    case "arbitrum":
      jsonRpcUrl = "https://arb1.arbitrum.io/rpc";
      break;
    case "optimism":
      jsonRpcUrl = "https://mainnet.optimism.io/";
      break;
    case "polygon":
      jsonRpcUrl = "https://polygon-rpc.com";
      break;
    default:
      jsonRpcUrl = "";
  }

  return jsonRpcUrl;
}

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
  const provider = new ethers.providers.JsonRpcProvider(getJsonRpcUrl("polygon"));
  const l1Wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
  const Master = await (
    await hre.ethers.getContractFactory(`${contractName}`)
  ).connect(l1Wallet);
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
    // Deploy the contract
    deployContract(answers.protocolName, answers.arg);
  })
  .catch((error) => {
    if (error.isTtyError) {
      // Prompt couldn't be rendered in the current environment
    } else {
      // Something else went wrong
    }
  });

// /Users/salilnaik/Documents/projects/socket/plugathon/contracts/Master.sol
// 0x794a61358d6845594f94dc1db02a252b5b4814ad
