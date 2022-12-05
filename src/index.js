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
      jsonRpcUrl = "https://mainnet.optimism.io";
      break;
    case "polygon":
      jsonRpcUrl = "https://holy-young-sound.matic.quiknode.pro/daf7877129f05fb4a21448bdd023cdf6f0faeefc/";
      break;
    default:
      jsonRpcUrl = "";
  }

  return jsonRpcUrl;
}

const socketAddress = {
  polygon: {
    address: "0x38e55351Dc02320A555b137e559D71f213694c15",
    chainId: 137,
  },
  arbitrum: {
    address: "0xa5b593ae839b3fe47983fc28da602a6deefbbc9d",
    chainId: 42161,
  },
  optimism: {
    address: "0x9E9b10A58a845B864265c49Fa24bb614f585498e",
    chainId: 10,
  },
};

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

async function deploySatellite(_userParams) {
  // to deploy satellite on multiple chains
  for (let i = 0; i < _userParams.chains.length; i++) {
    console.log("for loop", i);
    const provider = new ethers.providers.JsonRpcProvider(
      getJsonRpcUrl(_userParams.chains[0].toLowerCase())
    );
    // console.log(i, provider);
    let gasPrice;
    // console.log("aloolelo", await provider.getBalance('0x46DF89d79919283C395937a8b5b262191626F8e5'));
    try {
      gasPrice = await provider.getGasPrice();
    } catch (e) {
      console.log("Error while getting gas price: ", e);
    }
    const l1Wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

    const Satellite = (
      await hre.ethers.getContractFactory("Satellite")
    ).connect(l1Wallet);
    // console.log(i, Satellite);
    const currentChain = socketAddress[_userParams.chains[i].toLowerCase()];
    // console.log(i, currentChain);
    // console.log('current chain', currentChain, gasPrice)
    // console.log('current chain', currentChain.address)
    const gasLimit = currentChain.chainId == 42161 ? 4500000 : 1800000; 
    const mock = await Satellite.deploy(
      currentChain.address,
      "0x46DF89d79919283C395937a8b5b262191626F8e5",
      currentChain.chainId,
      { gasPrice: gasPrice.mul(ethers.BigNumber.from(2)), gasLimit: gasLimit }
    );
    // console.log("satellite mock", mock);
    try {
      console.log(`Deploying on ${_userParams.chains[i]}...`);
      const abc = await mock.deployed();
      console.log(`Deployed`);
    } catch (e) {
      console.log("Error", e);
    }
  }
}

async function deployContract(contractName, arg, _userParams) {
  // to deploy user's contract (controller)
  let chainToDeployOn;
  if (_userParams.scalability === "High") {
    chainToDeployOn = "polygon";
  } else if (_userParams.scalability === "Medium") {
    chainToDeployOn = "arbitrum";
  } else if (_userParams.scalability === "Low") {
    chainToDeployOn = "optimism";
  }

  const provider = new ethers.providers.JsonRpcProvider(
    getJsonRpcUrl(chainToDeployOn)
  );
  const gasPrice = await provider.getGasPrice();
  const l1Wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
  const Master = await (
    await hre.ethers.getContractFactory(`${contractName}`)
  ).connect(l1Wallet);
  const mock = await Master.deploy(arg, { gasPrice });

  await mock.deployed();

  // deploySatellite()
}

function main() {
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
      // {
      //   name: "protocol",
      //   message: "Enter the absolute path of your smart contract file",
      // },
      // {
      //   name: "protocolName",
      //   message: "Enter the protocol name",
      // },
      // {
      //   name: "arg",
      //   message: "Enter argument",
      // },
    ])
    .then(async (answers) => {
      userParams = answers;
      console.log("log", answers);
      // Make smart contract file
      // TODO: Enable later
      // await readFileData(answers.protocol, answers.protocolName);
      // Deploy the contract
      // deployContract(answers.protocolName, answers.arg, answers);
      deploySatellite(answers);
    })
    .catch((error) => {
      if (error.isTtyError) {
        // Prompt couldn't be rendered in the current environment
      } else {
        // Something else went wrong
      }
    });
}

main();

1966905394394349

// /Users/salilnaik/Documents/projects/socket/plugathon/contracts/Master.sol
// 0x794a61358d6845594f94dc1db02a252b5b4814ad
