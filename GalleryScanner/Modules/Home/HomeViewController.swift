import UIKit
import SwiftUI
import Photos
import Combine

class HomeViewController: UIViewController {
    private var homeVM = HomeViewModel()
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, String>!
    private var cancellables = Set<AnyCancellable>()
    
    private let statusLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .default)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupCollectionView()
        setupCollectionViewDelegate()
        setupDataSource()
        setupBindingVM()
        homeVM.requestPhotoAuthorization()
    }
}

extension HomeViewController {
    private func setupViews() {
        title = "All Groups"
        view.backgroundColor = .systemBackground
        
        progressView.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.textAlignment = .center
        
        view.addSubview(progressView)
        view.addSubview(statusLabel)
        
        
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)])
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, environment -> NSCollectionLayoutSection? in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(80))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = .init(top: 5, leading: 5, bottom: 5, trailing: 5)
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: itemSize, subitems: [item])
            let section = NSCollectionLayoutSection(group: group)
            return section
        }
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemBackground
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 12),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        collectionView.register(GroupCell.self, forCellWithReuseIdentifier: GroupCell.reuseIdentifier)
    }
    
    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Int,String>(collectionView: collectionView) { collectionView, indexPath, identifier in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GroupCell.reuseIdentifier, for: indexPath) as? GroupCell else {
                return UICollectionViewCell()
            }
            let count = self.homeVM.groupCounts[identifier] ?? 0
            cell.configure(title: identifier.capitalized, count: count)
            return cell
        }
        
        var snapshot = NSDiffableDataSourceSnapshot<Int,String>()
        snapshot.appendSections([0])
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    private func updateGroupUI() {
        var visible = homeVM.groupCounts.filter { $0.value > 0 }.map { $0.key }
        visible.sort()
        
        var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
        snapshot.appendSections([0])
        snapshot.appendItems(visible, toSection: 0)
        dataSource.applySnapshotUsingReloadData(snapshot)
    }
}

extension HomeViewController: UICollectionViewDelegate {
    private func setupCollectionViewDelegate() {
        collectionView.delegate = self
    }
    
    private func setupBindingVM() {
        homeVM.$groupCounts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.updateGroupUI()
            }
            .store(in: &cancellables)
        
        homeVM.$progress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                guard let self = self else { return }
                self.progressView.setProgress(value, animated: true)
            }
            .store(in: &cancellables)
        
        homeVM.$statusText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                guard let self = self else { return }
                self.statusLabel.text = text
            }
            .store(in: &cancellables)
        
        homeVM.showAlert
            .receive(on: DispatchQueue.main)
            .sink { [weak self] alert in
                guard let self = self else { return }
                self.present(alert, animated: true)
            }
            .store(in: &cancellables)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let id = dataSource.itemIdentifier(for: indexPath) else { return }
        
        let viewModel = GroupDetailViewModel(groupRaw: id)
        let view = GroupDetailView(viewModel: viewModel)
        let host = UIHostingController(rootView: view )
        navigationController?.pushViewController(host, animated: true)
    }
}


